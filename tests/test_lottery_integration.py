from brownie import Lottery, accounts, network, config, exceptions
from web3 import Web3
from scripts.deploy_lottery import deploy_lottery
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    get_account,
    fund_with_link,
    get_contract,
)
import pytest
import time


def test_can_pick_winner():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip()

    lottery = deploy_lottery()
    account = get_account()
    lottery.startLottery({"from": account})
    value = lottery.getEntranceFee() + 100000000
    lottery.enter({"from": account, "value": value})
    lottery.enter({"from": account, "value": value})
    lottery.enter({"from": account, "value": value})
    fund_with_link(lottery)
    lottery.endLottery({"from": account})
    # wait for respond from the node with the random number
    time.sleep(60)
    assert lottery.recentWinner() == account
    assert lottery.balance() == 0
