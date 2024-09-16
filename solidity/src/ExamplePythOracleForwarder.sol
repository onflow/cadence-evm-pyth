// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ExamplePythOracleForwarder {
    using Strings for uint256;

    IPyth pyth;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytesArrayToString(bytes[] memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 * data.length * 32);  // Assuming each bytes element is 32 bytes long
        uint256 strIndex = 0;

        for (uint256 i = 0; i < data.length; i++) {
            bytes32 element = bytes32(data[i]);
            for (uint256 j = 0; j < 32; j++) {
                uint8 b = uint8(element[j]);
                str[strIndex++] = alphabet[b >> 4];
                str[strIndex++] = alphabet[b & 0x0f];
            }
        }

        return string(str);
    }

    function stringToBytesArray(string memory str) public pure returns (bytes[] memory) {
        bytes memory strBytes = bytes(str);
        bytes[] memory result = new bytes[](strBytes.length);

        for (uint i = 0; i < strBytes.length; i++) {
            result[i] = new bytes(1);
            result[i][0] = strBytes[i];
        }

        return result;
    }

    function bytesArrayToString(bytes[] memory bytesArray) public pure returns (string memory) {
        bytes memory strBytes = new bytes(bytesArray.length);

        for (uint i = 0; i < bytesArray.length; i++) {
            require(bytesArray[i].length == 1, "Each bytes element must be 1 byte long");
            strBytes[i] = bytesArray[i][0];
        }

        return string(strBytes);
    }

    function fetchPrice(
        string calldata pythPriceUpdateDataStr,
        string calldata priceFeedIdStr
    ) public payable returns (uint256) {
        // Convert string types from Cadence to native byte types
        bytes[] memory priceUpdateData = stringToBytesArray(pythPriceUpdateDataStr);
        bytes32 priceFeedId = stringToBytes32(priceFeedIdStr);

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