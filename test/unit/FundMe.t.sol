// This is used for just test, this does not relate with the script

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
//We are trying to test src Fundme!
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address USER = makeAddr("name");
    uint constant SEND_VALUE = 1 ether;
    uint constant START_BAL = 10 ether;
    uint constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe funds = new DeployFundMe();
        (fundme, ) = funds.run();
        vm.deal(USER, START_BAL);
    }

    function testMinimumUsd() public view {
        console.log(fundme.MINIMUM_USD());
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerAddress() public view {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //We are trying saying that the next line should revert
        fundme.fund{value: 5}(); //This is going to fail, the value is not upto the minimum usd
    }

    function testGetVersion() public view {
        uint version = fundme.getVersion();
        assertEq(version, 4);
        console.log(version);
    }

    function testUpdateFundDataStructures() public funded {
        uint amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testFunderAddarray() public funded {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundme.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //Arrange
        uint StatingOwnerBal = fundme.getOwner().balance;
        uint StatingFundMeBal = address(fundme).balance;

        //Act
        // uint gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner());
        fundme.withdraw();
        // uint gasEnd = gasleft();
        // uint gasUsed = (gasStart - gasEnd)*tx.gasprice;

        //Assert
        uint EndingOwnerBal = fundme.getOwner().balance;
        uint EndingFundMeBal = address(fundme).balance;

        assertEq(EndingFundMeBal, 0);
        assertEq(StatingFundMeBal + StatingOwnerBal, EndingOwnerBal);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }
        uint StartingOwnerBal = fundme.getOwner().balance;
        uint StatingFundMeBal = address(fundme).balance;

        //ACT
        vm.prank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundme).balance == 0);
        assert(
            StartingOwnerBal + StatingFundMeBal == fundme.getOwner().balance
        );
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }
}
