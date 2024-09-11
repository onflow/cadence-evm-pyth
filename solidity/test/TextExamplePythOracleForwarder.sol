// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { ExamplePythOracleForwarder } from "../src/ExamplePythOracleForwarder.sol";
import { MockPyth } from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";

contract TestExamplePythPracleForwarder is Test {
    MockPyth public pyth;

    ExamplePythOracleForwarder public app;

    function setUp() public {
        pyth = new MockPyth(60, 1);
        app = new ExamplePythOracleForwarder(address(pyth));
    }

    function testGetGreeting() public view {
        string memory expectedGreeting = "1.0.0"; // Replace with the expected greeting
        string memory actualGreeting = app.getGreeting();
        assertEq(actualGreeting, expectedGreeting, "Greeting does not match expected value");
    }
}
