from brownie import FamilyMultiSigWallet, accounts


def deploy_family_mutlisig_wallet():
    account = accounts[0]
    family_multisig_wallet = FamilyMultiSigWallet.deploy(
        [account.address], 1, {"from": account}
    )
    return family_multisig_wallet


def main():
    deploy_family_mutlisig_wallet()
