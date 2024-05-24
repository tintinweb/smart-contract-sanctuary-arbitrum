// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title NameFilter
 * @notice It filters the character we do not allow in an Identity Name.
 * @dev It is in it's standalone as we might later on change the name filtering logic, allowing or removing unicodes
 */
contract NameFilter {
    function isNameValid(string calldata _str) external pure returns (bool valid_) {
        (valid_,) = isNameValidWithIndexError(_str);
        return valid_;
    }

    function isNameValidWithIndexError(string calldata _str) public pure returns (bool, uint256 index) {
        bytes memory strBytes = bytes(_str);
        uint8 charByte;
        uint16 charValue;

        if (strBytes.length == 0 || strBytes.length > 28) return (false, index);

        while (index < strBytes.length) {
            charByte = uint8(strBytes[index]);

            if (charByte >= 0xF0) return (false, index);

            if (charByte <= 0x7F) {
                // Single byte character (Basic Latin range)
                if (
                    !(charByte > 0x20 && charByte <= 0x7E) || charByte == 0xA0 || charByte == 0x23 || charByte == 0x24
                        || charByte == 0x3A || charByte == 0x2C || charByte == 0x40 || charByte == 0x2D
                ) {
                    return (false, index);
                }
                index += 1;
            } else if (charByte < 0xE0) {
                // Two byte character
                if (index + 1 >= strBytes.length) {
                    return (false, index); // Incomplete UTF-8 sequence
                }
                charValue = (uint16(uint8(strBytes[index]) & 0x1F) << 6) | (uint16(uint8(strBytes[index + 1])) & 0x3F);
                if (
                    charValue < 0x00A0 || charValue == 0x200B || charValue == 0xFEFF
                        || (charValue >= 0x2000 && charValue <= 0x206F) // General Punctuation
                        || (charValue >= 0x2150 && charValue <= 0x218F) // Number Forms
                        || (charValue >= 0xFF00 && charValue <= 0xFFEF) // Halfwidth and Fullwidth Forms
                        || (charValue >= 161 && charValue <= 191) // Latin-1 Supplement
                        || charValue == 215 || charValue == 247 // Multiplication and Division signs
                ) {
                    return (false, index);
                }
                index += 2;
            } else {
                // Three byte character (CJK, Cyrillic, Arabic, Hebrew, Hangul Jamo, etc.)
                if (index + 2 >= strBytes.length) {
                    return (false, index); // Incomplete UTF-8 sequence
                }
                charValue = (uint16(uint8(strBytes[index]) & 0x0F) << 12)
                    | (uint16(uint8(strBytes[index + 1]) & 0x3F) << 6) | (uint16(uint8(strBytes[index + 2])) & 0x3F);
                if (
                    (charValue >= 0x1100 && charValue <= 0x11FF) // Hangul Jamo
                        || (charValue >= 0x0410 && charValue <= 0x044F) // Cyrillic
                        || (charValue >= 0x3040 && charValue <= 0x309F) // Hiragana
                        || (charValue >= 0x30A0 && charValue <= 0x30FF) // Katakana
                        || (charValue >= 0xAC00 && charValue <= 0xD7AF) // Hangul
                        || (charValue >= 0x0600 && charValue <= 0x06FF) // Arabic
                        || (charValue >= 0x05D0 && charValue <= 0x05EA) // Hebrew
                        || (charValue >= 20_000 && charValue <= 20_099) // Chinese limited range
                ) {
                    index += 3;
                } else {
                    return (false, index);
                }
            }
        }

        return (true, index);
    }
}