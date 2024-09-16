// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract ExamplePythOracleForwarder {
    IPyth pyth;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    function bytesToHexString(bytes[] memory data) public pure returns (string memory) {
        uint totalLength = 0;
        for (uint i = 0; i < data.length; i++) {
            totalLength += data[i].length;
        }

        bytes memory result = new bytes(totalLength * 2 + 2);
        result[0] = "0";
        result[1] = "x";

        uint index = 2;
        for (uint i = 0; i < data.length; i++) {
            for (uint j = 0; j < data[i].length; j++) {
                result[index] = byteToChar(uint8((uint256(uint8(data[i][j])) >> 4) & 0xF));
                result[index + 1] = byteToChar(uint8(uint256(uint8(data[i][j])) & 0xF));
                index += 2;
            }
        }

        return string(result);
    }

    function byteToChar(uint8 b) private pure returns (bytes1) {
        if (b < 10) return bytes1(b + 48);
        else return bytes1(b + 87);
    }

    function hexStringToBytes(string memory str) public pure returns (bytes[] memory) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length % 2 == 0, "Invalid hex string: not even");
        require(strBytes[0] == "0" && strBytes[1] == "x", "Missing 0x prefix");

        uint length = (strBytes.length - 2) / 2;
        bytes[] memory result = new bytes[](1);
        result[0] = new bytes(length);

        for (uint i = 0; i < length; i++) {
            uint8 high = charToByte(strBytes[2*i+2]);
            uint8 low = charToByte(strBytes[2*i+3]);
            result[0][i] = bytes1((high << 4) | low);
        }

        return result;
    }

    function charToByte(bytes1 c) private pure returns (uint8) {
        if (uint8(c) >= 48 && uint8(c) <= 57) return uint8(c) - 48;
        if (uint8(c) >= 97 && uint8(c) <= 102) return uint8(c) - 87;
        if (uint8(c) >= 65 && uint8(c) <= 70) return uint8(c) - 55;
        revert("Invalid hex character");
    }

    function bytes32ToHexString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(64);
        for (uint256 i; i < 32; i++) {
            bytesArray[i*2] = bytes1(uint8(uint256(_bytes32) / (2**(8*(31 - i))) / 16));
            bytesArray[i*2+1] = bytes1(uint8(uint256(_bytes32) / (2**(8*(31 - i))) % 16));
        }

        for (uint256 i; i < 64; i++) {
            uint8 value = uint8(bytesArray[i]);
            if (value < 10) {
                bytesArray[i] = bytes1(uint8(48 + value));
            } else {
                bytesArray[i] = bytes1(uint8(87 + value));
            }
        }

        return string(abi.encodePacked(bytesArray));
    }

    function hexStringToBytes32(string memory _hexString) public pure returns (bytes32) {
        bytes memory bytesString = bytes(_hexString);
        require(bytesString.length == 64, "Invalid bytes32 hex string"); // Changed to expect 64 characters

        bytes32 result;
        for (uint256 i = 0; i < 32; i++) {
            uint8 high = uint8(hexCharToByte(bytesString[2 * i]));
            uint8 low = uint8(hexCharToByte(bytesString[2 * i + 1]));
            result |= bytes32(uint256(high << 4 | low) << (8 * (31 - i)));
        }
        return result;
    }

    function hexCharToByte(bytes1 c) internal pure returns (uint8) {
        if (uint8(c) >= 48 && uint8(c) <= 57) {
            return uint8(c) - 48;
        }
        if (uint8(c) >= 65 && uint8(c) <= 70) {
            return uint8(c) - 55;
        }
        if (uint8(c) >= 97 && uint8(c) <= 102) {
            return uint8(c) - 87;
        }
        revert("Invalid hex character");
    }

    /**
    function compareBytes(bytes[] memory a, bytes[] memory b) public pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }

        for (uint i = 0; i < a.length; i++) {
            if (keccak256(a[i]) != keccak256(b[i])) {
                return false;
            }
        }

        return true;
    }

    function compareBytes32(bytes32 a, bytes32 b) public pure returns (bool) {
        return a == b;
    }**/
    /**
    function fetchPrice2(
        bytes[] memory priceUpdateData,
        bytes32 priceFeedId
    ) public payable returns (uint256) {
        string memory strPriceUpdateData = bytesToHexString(priceUpdateData);
        string memory strPriceFeedId = bytes32ToHexString(priceFeedId);

        // Convert string types from Cadence to native byte types
        bytes[] memory priceUpdateDataConv = hexStringToBytes(strPriceUpdateData);
        bytes32 priceFeedIdConv = hexStringToBytes32(strPriceFeedId);

        require(compareBytes(priceUpdateData, priceUpdateDataConv));
        require(compareBytes32(priceFeedId, priceFeedIdConv), "did not equal");

    uint updateFee = pyth.getUpdateFee(priceUpdateDataConv);
        pyth.updatePriceFeeds{value: updateFee}(priceUpdateDataConv);

        // Fetch the latest price
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(
            priceFeedIdConv,
            60
        );

        uint tokenPriceToTokenExpoDecimals = (uint(uint64(price.price)) * (10 ** 18)) /
            (10 ** uint8(uint32(-1 * price.expo)));

        return tokenPriceToTokenExpoDecimals;
    }**/

    function fetchPrice(
        string calldata pythPriceUpdateDataStr,
        string calldata priceFeedIdStr
    ) public payable returns (uint256) {
        // Convert string types from Cadence to native byte types
        bytes[] memory priceUpdateData = hexStringToBytes(pythPriceUpdateDataStr);
        bytes32 priceFeedId = hexStringToBytes32(priceFeedIdStr);

        uint updateFee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: updateFee}(priceUpdateData);

        // Fetch the latest price
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(
            priceFeedId,
            60
        );

        uint tokenPriceToTokenExpoDecimals = (uint(uint64(price.price)) * (10 ** 18)) /
            (10 ** uint8(uint32(-1 * price.expo)));

        return tokenPriceToTokenExpoDecimals;
    }

    // Error raised if the payment is not sufficient
    error InsufficientFee();
}