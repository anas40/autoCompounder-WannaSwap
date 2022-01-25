from brownie import WannaCompounder, network, config, accounts, interface


def get_account():
    if network.show_active() == "aurora-mainnet":
        # random private key
        account = accounts.add(
            "0x4d9f6e88ca8517d52fd0f62ed02e76e35cedbf7015b9586c2c2e13b8a51e0bad"
        )
        return account
    return accounts.at(
        config["networks"][network.show_active()]["cmd_settings"]["unlock"], force=True
    )


def withdraw_lp_from_farm():
    account = get_account()
    farm_contract = get_interface("wanna_farm")
    farm_pid = config["networks"][network.show_active()]["farm_pid"]
    # fetching lp amount
    lp_amount_locked = farm_contract.userInfo(farm_pid, account)[0]
    print("lp locked in farm : ", lp_amount_locked)

    print("withdrawing lp from farm to my account")
    (farm_contract.withdraw(farm_pid, lp_amount_locked, {"from": account})).wait(1)

    print_lp_balance()


def print_lp_balance():
    account = get_account()

    near_aurora_lp_token_contract = get_interface("near_aurora_lp_token")

    balance = near_aurora_lp_token_contract.balanceOf(account)
    print("LP balance of ", account, " is : ", balance)


def deploy_contract():
    account = get_account()
    print(account)
    return WannaCompounder.deploy(
        config["networks"][network.show_active()]["wanna_near_path"],
        config["networks"][network.show_active()]["wanna_aurora_path"],
        {"from": account,"gas_limit":3000000}
    )


def approve_lp_for_harvester(wanna_seller_contract):
    account = get_account()
    near_aurora_lp_token_contract = get_interface("near_aurora_lp_token")

    balance = near_aurora_lp_token_contract.balanceOf(account)
    address = wanna_seller_contract.address

    tx = near_aurora_lp_token_contract.approve(address, balance, {"from": account})
    tx.wait(1)


def depostiLP(wanna_seller_contract):
    account = get_account()
    near_aurora_lp_token_contract = get_interface("near_aurora_lp_token")

    balance = near_aurora_lp_token_contract.balanceOf(account)

    tx = wanna_seller_contract.depositLP(balance, {"from": account})
    tx.wait(1)


def get_arora_balance(address):
    account = get_account()
    arora_token_contract = get_interface("arora_token")
    return arora_token_contract.balanceOf(address, {"from": account})


def passtime():
    withdraw_lp_from_farm()
    withdraw_lp_from_farm()
    withdraw_lp_from_farm()


def main():

    if network.show_active() == "aurora-mainnet":
        deploy_contract()
        return

    account = get_account()

    withdraw_lp_from_farm()

    # deploying auto Compounder contract
    print("Deploying Compounder...")
    wanna_seller_contract = deploy_contract()

    print("Approving lp token for Compounder...")
    approve_lp_for_harvester(wanna_seller_contract)

    print("Sending lp token to Compounder...")
    depostiLP(wanna_seller_contract)

    print("Depositing lp from Compounder to farm")
    (wanna_seller_contract.depositLPtoFarm({"from": account})).wait(1)

    passtime()
    # compounding and sending yield to myself
    print("Doing the harvesting...")
    (wanna_seller_contract.harvestAndCompound({"from": account})).wait(1)

    # withdraw lp
    print("Withdrawing the lp from farm to Compounder")
    (wanna_seller_contract.withdrawLPfromFarm({"from": account})).wait(1)

    # it also send the lp to main account
    print("Withdrawing the lp from Compounder to account")
    (wanna_seller_contract.withdrawLP({"from": account})).wait(1)

    print_lp_balance()


def get_interface(name):

    interfaces = {
        "near_aurora_lp_token": {
            "address": config["networks"][network.show_active()][
                "near_aurora_lp_token_address"
            ],
            "type": "IERC20",
        },
        "arora_token": {
            "address": config["networks"][network.show_active()][
                "aurora_token_address"
            ],
            "type": "IERC20",
        },
        "wanna_farm": {
            "address": config["networks"][network.show_active()]["wanna_farm_address"],
            "type": "IWannaFarm",
        },
    }

    if interfaces[name]["type"] == "IERC20":
        contract = interface.IERC20(interfaces[name]["address"])

    if interfaces[name]["type"] == "IWannaFarm":
        contract = interface.IWannaFarm(interfaces[name]["address"])

    return contract
