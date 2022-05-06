from scripts.deploy import deploy_family_mutlisig_wallet
from brownie import accounts
from web3 import Web3


def test_can_submit_transaction():
    family_multisig_wallet = deploy_family_mutlisig_wallet()
    # act
    account = accounts[0]
    sending_to = accounts[1]
    tx = family_multisig_wallet.submit(
        sending_to.address,
        Web3.fromWei(1000000000000000000, "ether"),
        "0x",
        {"from": account},
    )
    tx.wait(1)

    # assert
    # asserting that the variable tx is equal to the latest transaction in the transactions array of the multisig wallet
    latest_transaction = family_multisig_wallet.transactions.call(0, {"from": account})
    assert tx == latest_transaction
