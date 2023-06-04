// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEntryFee;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    // address payable public owner;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;
    uint256 fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    // add VRFV2WrapperConsumerBase inside our constructor
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        // owner = payable(msg.sender);
        usdEntryFee = 50 * 10 ** 18;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // 50$ minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee());
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // $50, $2000 / ETH
        // 50/2000
        // 50 * precise/2000
        uint256 adjustPrice = uint256(price) * 10 ** 10; //18 decimals
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustPrice;
        return costToEnter;
    }

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "The owner only can withdraw funds!");
    //     _; // underscore denotes when the function to which we apply the modifier will be executed, in this case we will at first check the requirement and then execute function
    // }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // take a random winner index - a bad way
        // keccak256 is a hash algorithm
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce, // nonce is predictable
        //             msg.sender, // predictable
        //             block.difficulty, // can be manipulated by the miners!
        //             block.timestamp   // predictable
        //         )
        //     )
        // ) % players.length;

        // take a random winner index - a good way
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    // we override fulfillRandomness function stated in VRFConsumerBase to get random values
    // fulfillRandomness in VRFConsumerBase is virtual type meaning that it's supposed to be overriden
    function fulfillRandomness(
        bytes32 requestId,
        uint256 _randomness
    ) internal override {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Wrong stage to call this function"
        );
        require(_randomness > 0, "random not found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        // Reset the lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
