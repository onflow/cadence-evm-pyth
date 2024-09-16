// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { ExamplePythOracleForwarder } from "../src/ExamplePythOracleForwarder.sol";
import { MockPyth } from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";

contract TestExamplePythOracleForwarder is Test {
    MockPyth public pyth;
    bytes32 ETH_PRICE_FEED_ID = bytes32(uint256(0x1));
    uint256 ETH_TO_WEI = 10 ** 18;

    ExamplePythOracleForwarder public app;

    function setUp() public {
        pyth = new MockPyth(60, 1);
        app = new ExamplePythOracleForwarder(address(pyth));
    }

    function createEthUpdate(
        int64 ethPrice
    ) private view returns (bytes[] memory) {
        bytes[] memory updateData = new bytes[](1);
        updateData[0] = pyth.createPriceFeedUpdateData(
            ETH_PRICE_FEED_ID,
            ethPrice * 100000, // price
            10 * 100000, // confidence
            -5, // exponent
            ethPrice * 100000, // emaPrice
            10 * 100000, // emaConfidence
            uint64(block.timestamp), // publishTime
            uint64(block.timestamp) // prevPublishTime
        );

        return updateData;
    }

    function setEthPrice(int64 ethPrice) private {
        bytes[] memory updateData = createEthUpdate(ethPrice);
        uint value = pyth.getUpdateFee(updateData);
        vm.deal(address(this), value);
        pyth.updatePriceFeeds{ value: value }(updateData);
    }

    function testFetchPriceReturnsLatestPrice() public {
        setEthPrice(100);

        bytes[] memory updateData = createEthUpdate(100);
        bytes32 validPriceFeedId = ETH_PRICE_FEED_ID;

        console2.log(updateData[0].length);

        string memory pythPriceUpdateDataString = app.bytesToHexString(updateData);
        string memory priceFeedIdString = app.bytes32ToHexString(validPriceFeedId);

        console2.log(pythPriceUpdateDataString);
        console2.log(bytes(priceFeedIdString).length);

        vm.deal(address(this), ETH_TO_WEI);

        uint256 result = app.fetchPrice{ value: ETH_TO_WEI / 100 }(pythPriceUpdateDataString, priceFeedIdString);
        assertGt(result, 0, "Price should be greater than zero");
    }
}
