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

        bytes memory result = new bytes(totalLength * 2);

        uint index = 0;
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
        bytes memory hexChars = "0123456789abcdef";
        bytes memory result = new bytes(66); // 2 characters per byte + '0x' prefix
        result[0] = '0';
        result[1] = 'x';

        for (uint256 i = 0; i < 32; i++) {
            result[2 + i * 2] = hexChars[uint8(_bytes32[i] >> 4)];
            result[3 + i * 2] = hexChars[uint8(_bytes32[i] & 0x0f)];
        }

        return string(result);
    }

    function hexStringToBytes32(string memory _hexString) public pure returns (bytes32) {
        bytes memory bytesString = bytes(_hexString);
        require(bytesString.length == 66, "Invalid hex string length");

        bytes32 result;
        for (uint256 i = 0; i < 64; i++) {
            result |= bytes32(uint256(fromHexChar(uint8(bytesString[i + 2])))) << (252 - i * 4);
        }
        return result;
    }

    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
        revert("Invalid hex character");
    }

    receive() external payable {}

    function fetchPrice(
        string calldata pythPriceUpdateDataStr,
        string calldata priceFeedIdStr
    ) public payable returns (uint256) {
        // Convert string types from Cadence to byte types
        bytes[] memory priceUpdateData = hexStringToBytes(pythPriceUpdateDataStr);
        bytes32 priceFeedId = hexStringToBytes32(priceFeedIdStr);
        return fetchPriceNativeArgs(priceUpdateData, priceFeedId);
    }


    function fetchPriceNativeArgs(
        bytes[] memory priceUpdateData,
        bytes32 priceFeedId
    ) public payable returns (uint256) {
        uint updateFee = pyth.getUpdateFee(priceUpdateData);

        try pyth.updatePriceFeeds{value: updateFee}(priceUpdateData) {
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Pyth update failed: ", reason)));
        }

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