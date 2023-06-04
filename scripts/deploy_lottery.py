from brownie import Lottery, accounts, config, network
from scripts.helpful_scripts import get_account, get_contract, fund_with_link
import time


def deploy_lottery():
    account = get_account()
    lottery = Lottery.deploy(
        get_contract("eth_usd_price_feed").address,
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print("Lottery deployed!")
    return lottery


def start_lottery():
    account = get_account()
    lottery = Lottery[-1]
    starting_tx = lottery.startLottery({"from": account})
    starting_tx.wait(1)
    print("The Lottery's started!")


def enter_lottery():
    account = get_account()
    lottery = Lottery[-1]
    value = lottery.getEntranceFee() + 100000000
    entering_tx = lottery.enter({"from": account, "value": value})
    entering_tx.wait(1)
    print("You've entered the lottery!")


def end_lottery():
    account = get_account()
    lottery = Lottery[-1]
    # fund the contract with LINK
    funding_tx = fund_with_link(lottery.address)
    funding_tx.wait(1)
    # end the lottery
    endning_tx = lottery.endLottery({"from": account})
    endning_tx.wait(1)

    # here, we wait for 60 seconds for the node responding to our requestRandomness function
    # when the node responding it calls fulfillRandomness function, get the winner and close the lottery
    time.sleep(120)

    print(f"{lottery.recentWinner()} is the new winner")


def main():
    print(network.show_active())
    print(type(network.show_active()))
    deploy_lottery()
    start_lottery()
    enter_lottery()
    end_lottery()
