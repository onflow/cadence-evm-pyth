// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { ExamplePythOracleForwarder } from "../src/ExamplePythOracleForwarder.sol";
import { MockPyth } from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";

contract TestExamplePythOracleForwarder is Test {
    MockPyth public pyth;
    bytes32 ETH_PRICE_FEED_ID = bytes32(0x0cb1d89c96c1ffd317525b8a30d650882bf6fcef43b1239a17a9ad9fb28de0e1);
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

    function testBytes32ToHexString() public {
        setEthPrice(100);

        string memory hexString = "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6";
        bytes32 realHex = bytes32(0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6);
        string memory decodedHex = app.bytes32ToHexString(realHex);

        assertEq(decodedHex, hexString, "Hex decoding values not matched");
    }


    function testHexStringToBytes32() public {
        setEthPrice(100);

        bytes32 realHex = bytes32(0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6);
        string memory hexString = "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6";
        bytes32 encodedHex = app.hexStringToBytes32(hexString);

        assertEq(encodedHex, realHex, "Hex values not matched");
    }


    function testFetchPriceReturnsLatestPrice() public {
        setEthPrice(100);

        bytes[] memory updateData = createEthUpdate(100);
        bytes32 validPriceFeedId = ETH_PRICE_FEED_ID;

        console2.log(updateData[0].length);

        string memory pythPriceUpdateDataString = app.bytesToHexString(updateData);
        string memory priceFeedIdString = app.bytes32ToHexString(validPriceFeedId);

        console2.log(pythPriceUpdateDataString);
        console2.log(bytes(pythPriceUpdateDataString).length);
        console2.log(priceFeedIdString);
        console2.log(bytes(priceFeedIdString).length);

        vm.deal(address(this), ETH_TO_WEI);

        uint256 result = app.fetchPrice{ value: ETH_TO_WEI / 100 }(pythPriceUpdateDataString, priceFeedIdString);
        assertGt(result, 0, "Price should be greater than zero");
    }

}
