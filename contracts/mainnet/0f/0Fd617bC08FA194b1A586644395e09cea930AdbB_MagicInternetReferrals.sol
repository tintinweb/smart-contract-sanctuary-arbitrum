/*
  
                               ▄▄▄▄,_
                           _▄████▀└████▄,
                       ▄███████▌   _▄█████▄_
                      ╓████████▄██▄╟██████████▄
                     ╓█████▀▀█████████████⌐ ╓████▄_
                     ╟███`     ╟███████████████████
                      ██▌     ▐████╙▀▐████████▀╙"╙▀" ,▄▄,
                     ,█▀       ,██▄▄ ▄▄█████w     ╒████████▄▄▄▄▄▄▄▄▄,,__
                              ª▀▀▀▀▀▀▀▀"" _,▄▄_▄▄█████████████████████▀▀
                            ╒██▄▄▄▄▄▄███████████████████████████▀▀╙"
                            ▐███████████████████▀▀▀▀▀╙╙"─
                         ▄██████████▀▀▀╙"`
                     ,▄███████▀""
                  ▄███████▀"                               _▄▄█▀▀████▄▄_
              ,▄████████▀                _,▄▄▄,_        ,███▀╓█▄   ╙█████▄
            ▄████████▀"             _▄█▀▀""╙▀██████▄ ╓█████▌ ╙▀"███L╙█████▌
             """╙"─               ▄███▐██▌╓██▄╙████████████▌ ╚█_`▀▀  ████▀
                              _▄█████" └█▄╙██▀ ╫████████████┐  ╙    '"─
                            '▀███████▌  "█─    ▐▀▀"  └"╙▀▀▀╙"         ▄▄_
                                 ╙▀▀██▌                           ,▄█████
                         ,▄▄▄▄▄▄▄▄,______              ___,▄▄▄█████████▀"
                        ██████████████████████████████████████████████▄
                        ╙██████████████████████████████████████████████
                            '╙▀▀█████████████████████████████████▀▀▀╙─
                                     `""╙"╙╙""╙╙╙╙""╙╙"""─`


*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMagicInternetMana {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IMagicInternetFrens {
    function getTokenId() external view returns (uint256);
    function mint(address fren) external returns (uint256);
}

contract MagicInternetReferrals {
    IMagicInternetMana public miManaToken;
    IMagicInternetFrens public miFrenNFT;
    address public owner;
    mapping(address => bool) public isSignedUp;
    mapping(string => address) public referralCodeToAddress;
    mapping(string => bool) public usedReferralCodes;
    mapping(address => address) public referedBy;
    mapping(uint256 => address) public tokenIdReferedBy;
    mapping(address => bool) public isAuth;
    mapping(address => uint256) public referralRewardsETH;
    mapping(address => uint256) public referralRewardsMANA;
    bytes private constant CHARACTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    uint256 private constant CHARACTERS_LENGTH = 62;
    uint256 private referralCodeCounter = 0;
    uint256 public mintPriceETH = 0.05 ether;
    uint256 public mintPriceETHReferral = 0.015 ether;
    uint256 public mintPriceMana = 100 ether;
    uint256 public maxReferralLevels = 3;
    bool public mintETH = true;
    mapping(address => string[]) public referralCodesByAddress;

    // Constructor
    constructor(address miFren, address miMana) {
        owner = msg.sender;
        referralCodeCounter = 0;
        miManaToken = IMagicInternetMana(miMana);
        miFrenNFT = IMagicInternetFrens(miFren);
    }

    // Modifier to restrict access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    event NewSignUp(address indexed user, string referralCode);
    event ReferralCodeGenerated(address indexed user, string referralCode);

    function setmintPriceETH(bool isETH) public onlyOwner {
        mintETH = isETH;
    }

    function setmintToken(uint256 newPrice) public onlyOwner {
        mintPriceETH = newPrice;
    }

    function setmintPriceMANA(uint256 newPrice) public onlyOwner {
        mintPriceMana = newPrice;
    }

    function mint() public payable {
        if (mintETH) {
            require(msg.value >= mintPriceETH, "plis gib more ETH fren");
        }
        miFrenNFT.mint(msg.sender);
        isSignedUp[msg.sender] = true;
    }

    function calculateReward(uint256 amount, uint level) internal pure returns (uint256) {
        if (level == 0) {
            return (amount * 10) / 100; // 10% for direct referral
        } else if (level == 1) {
            return (amount * 1) / 100; // 1% for the referrer of the referrer
        } else if (level == 2) {
            return (amount * 1) / 1000; // 0.1% for the referrer of the referrer of the referrer
        }
        return 0;
    }

    function signUpReferral(string memory code) public payable {
        require(!isSignedUp[msg.sender], "Already signed up");
        require(!usedReferralCodes[code], "Referral code already used");
        require(referralCodeToAddress[code] != address(0), "Invalid referral code");
        uint256 newTokenId = miFrenNFT.getTokenId();
        isSignedUp[msg.sender] = true;
        usedReferralCodes[code] = true;
        referedBy[msg.sender] = referralCodeToAddress[code];
        deleteReferralCode(referralCodeToAddress[code], code);
        if (mintETH) {
            require(msg.value >= mintPriceETHReferral, "plis gib more ETH fren");

            if (referedBy[msg.sender] != address(0)) {
                address currentReferrer = msg.sender;
                uint256 remainingReward = mintPriceETHReferral;
                tokenIdReferedBy[newTokenId] = referedBy[msg.sender];

                for (uint i = 0; i < maxReferralLevels && currentReferrer != address(0); i++) {
                    uint256 reward = calculateReward(remainingReward, i);
                    referralRewardsETH[currentReferrer] += reward;
                    remainingReward -= reward;
                    currentReferrer = referedBy[currentReferrer];
                }
            }
        } else {
            require(miManaToken.balanceOf(msg.sender) >= mintPriceMana, "Not enough miMana tokens");
            miManaToken.transferFrom(msg.sender, address(this), mintPriceMana);
            if (referedBy[msg.sender] != address(0)) {
                address currentReferrer = msg.sender;
                uint256 remainingReward = mintPriceMana;
                tokenIdReferedBy[newTokenId] = referedBy[msg.sender];

                for (uint i = 0; i < maxReferralLevels && currentReferrer != address(0); i++) {
                    uint256 reward = calculateReward(remainingReward, i);
                    referralRewardsETH[currentReferrer] += reward;
                    remainingReward -= reward;
                    currentReferrer = referedBy[currentReferrer];
                }
            }
        }
        miFrenNFT.mint(msg.sender);

        emit NewSignUp(msg.sender, code);
    }

    function generateReferralCode() public returns (string memory) {
        require(isSignedUp[msg.sender] || msg.sender == owner, "Not authorized to generate code");

        referralCodeCounter++;
        bytes memory code = new bytes(6);

        for (uint256 i = 0; i < 6; i++) {
            uint256 rand = uint256(
                keccak256(abi.encodePacked(referralCodeCounter, block.difficulty, block.timestamp, i))
            );
            code[i] = CHARACTERS[rand % CHARACTERS_LENGTH];
        }

        string memory newCode = string(abi.encodePacked("mifren-ARB-", string(code)));
        referralCodeToAddress[newCode] = msg.sender;
        referralCodesByAddress[msg.sender].push(newCode);

        emit ReferralCodeGenerated(msg.sender, newCode);
        return newCode;
    }

    function getReferralCodesByAddress(address userAddress) public view returns (string[] memory) {
        return referralCodesByAddress[userAddress];
    }

    function claimRewardsETH() public {
        uint256 reward = referralRewardsETH[msg.sender];
        require(reward > 0, "No rewards to claim");

        referralRewardsETH[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
    }

    function claimMANA() public {
        uint256 reward = referralRewardsMANA[msg.sender];
        require(reward > 0, "No rewards to claim");

        // Reset the user's referral reward balance
        referralRewardsMANA[msg.sender] = 0;

        // Transfer the miMana tokens from the contract to the user
        require(miManaToken.transfer(msg.sender, reward), "Transfer failed");
    }

    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function deleteReferralCode(address referalAddress, string memory codeToDelete) private {
        int256 indexToDelete = -1;
        for (uint i = 0; i < referralCodesByAddress[referalAddress].length; i++) {
            if (keccak256(bytes(referralCodesByAddress[referalAddress][i])) == keccak256(bytes(codeToDelete))) {
                indexToDelete = int256(i);
                break;
            }
        }

        if (indexToDelete != -1) {
            removeCodeAtIndex(uint256(indexToDelete), referalAddress);
        }
    }

    // Helper function to remove a code from the array at a given index
    function removeCodeAtIndex(uint256 index, address userAddress) private {
        require(index < referralCodesByAddress[userAddress].length, "Index out of bounds");

        // Move the last element into the place to delete and pop the last element
        referralCodesByAddress[userAddress][index] = referralCodesByAddress[userAddress][
            referralCodesByAddress[userAddress].length - 1
        ];
        referralCodesByAddress[userAddress].pop();
    }

    function getTokenIdReferedBy(uint256 tokenId) public view returns (address) {
        return tokenIdReferedBy[tokenId];
    }

    function getReferedBy(address fren) public view returns (address) {
        return referedBy[fren];
    }

    // Additional functions like transferring ownership can be added if needed
}