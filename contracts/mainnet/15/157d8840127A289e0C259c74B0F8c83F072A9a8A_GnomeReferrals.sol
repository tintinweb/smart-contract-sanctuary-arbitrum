// SPDX-License-Identifier: MIT
/*

░██████╗░███╗░░██╗░█████╗░███╗░░░███╗███████╗██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔════╝░████╗░██║██╔══██╗████╗░████║██╔════╝██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██╗░██╔██╗██║██║░░██║██╔████╔██║█████╗░░██║░░░░░███████║██╔██╗██║██║░░██║
██║░░╚██╗██║╚████║██║░░██║██║╚██╔╝██║██╔══╝░░██║░░░░░██╔══██║██║╚████║██║░░██║
╚██████╔╝██║░╚███║╚█████╔╝██║░╚═╝░██║███████╗███████╗██║░░██║██║░╚███║██████╔╝
░╚═════╝░╚═╝░░╚══╝░╚════╝░╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

                                   ╓╓╓▄▄▄▓▓█▓▓▓▓▀▀▀▀▀▀▓█
                             ╓▄██▀╙╙░░░░░░░░░░░░░░░░╠╬║█
                        ╓▄▓▀╙░░░░░░░░░░░░░░░░░░░░░░╠╠╠║▌
                     ╓█╩░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠╠╠║▌
                   ▄█▒░░░░░░░░░░░░░▒▄██████▄▄░░░░░╠╠╠╠║▌
                 ╓██▀▀▀╙╙╚▀░░░░░▄██╩░░░░░░░░╙▀█▄▒░╠╠╠╠╬█
              ╓▓▀╙░░░░░░░░░░░░░╚╩░░░░░░░░░░░░░░╙▀█╠╠╠╠╬▓
             ▄╩░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠╠╠╠║▌
            ║██▓▓▓▓▓▄▄▒░░░░░░░░░░░▄▄██▓█▄▄▒░░░░░░░╠╠╠╠╠╬█
           ╔▀         ╙▀▀█▓▄▄▄██▀╙       └╙▀█▄▒░░░╠╠╠╠╠╠║▌
          ║█▀▀╙╙╙▀▀▓▄╖       ▄▄▓▓▓▓╗▄▄╓      ╙╙█▄▒░╠╠╠╠╠╬█
        ╓▀   ╓╓╓╓╓╓   ╙█▄ ▄▀╙          ╙▀▓▄      ╙▀▓▒▒╠╠╠║▌
        ▐██████████╙╙▀█▄ ╙█▄▓████████▀▀╗▄           █▀███╬█
        █║██████▌ ██    ╙██╓███████╙▀█   └▀╗╓       ║▒   ╙╙▓
       ╒▌╫███████╦╫█     ║ ╫███████╓▄█▌     └█╕     ║▌    ▀█▀▀
        █╚██████████    ╓╣ ║██████████▒    ╔▀╙      ║▒     └█
       ┌╣█╣████████╓╓▄▓▓▒▄█▄║████████▌╓╗╗▀╙        ╓█        ╚▄
       │█▄╗▀▀╙      ╙▀╙         ╙▀▀██▒            ▄█          ╙▄
     █▒                               ╙▀▀▀▀╠█▌╓▄▓▀             ║
      ╙█╓           ╓╓                   ╓██╩║▌                ║
       ╓╣███▄▄▄▄▓██╬╬╠╬███▄▄▄▄╓╓╓╓╓▄▄▄▓█╬╬▒░░╠█             ╔ ┌█
      ╓▌  ▀█╬╬▒╠╠╠╠░▒░░░╠╠╠╚╚╚╩╠╠╠╠╬███▀╩░░░▄█        ▓      █▀
     ╒▌   ╘█░╚╚╚╚╚▀▀▀▀▀▀▀▀▀▀▀▀▀▀╚╚╚░░░░░░▄█▀╙         ║      ▐▌
     ╟     └▀█▄▒▒▒░░░░░░░░░░░▒▒▒▒▒▄▄█▓╝▀╙                    ▐▌
     ║░        ╙╙▀▀▀▀▀▀▀▀▀▀▀▀▀▀╙╙                        ╓   █
      █                                                  ▓ ╓█
      ║▌   ╔                                            ╔█▀
       █   ╚▄                              ╓╩          ╔▀
       ╚▌   ╙                             ▓▀         ╓█╙
        ╙▌          ▐                  ╓═    ▄    ╓▄▀╙
          ▀▄        ╙▒                      ▄██▄█▀
            ╙▀▄╓║▄   └                    ▄╩
                ╙▀█                   ╓▄▀▀
                   ▀▓        ▄▄▓▀▀▀▀╙
                     └▀╗▄╓▄▀╙
    
    
https://www.gnomeland.money/
https://twitter.com/Gnome0xLand

$GNOMES
$GNOME

Everywhere...

*/
pragma solidity ^0.8.20;

interface IGNOME {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IGNOMENFT {
    function getTokenId() external view returns (uint256);
    function mint(address fren) external returns (uint256);
}

contract GnomeReferrals {
    IGNOME public gnomeToken;

    address public owner;
    mapping(address => bool) public isSignedUp;
    mapping(string => address) public referralCodeToAddress;
    mapping(string => bool) public usedReferralCodes;
    mapping(address => address) public referedBy;
    mapping(uint256 => address) public tokenIdReferedBy;
    mapping(address => bool) public isAuth;
    mapping(address => uint256) public referralRewardsETH;
    mapping(address => uint256) public referralRewardsGNOME;
    bytes private constant CHARACTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    uint256 private constant CHARACTERS_LENGTH = 62;
    uint256 private referralCodeCounter = 0;
    bool public referralopen = true;

    uint256 public mintPriceETHReferral = 0.015 ether;
    uint256 public referralPriceGnome = 100 ether;
    uint256 public maxReferralLevels = 3;
    uint256 public referralPrice = 1001 ether;
    bool public mintETH = true;
    mapping(address => string[]) public referralCodesByAddress;
    modifier onlyAuth() {
        require(msg.sender == owner || isAuth[msg.sender], "Caller is not the authorized");
        _;
    }

    // Constructor
    constructor(address gnome) {
        owner = msg.sender;
        isAuth[msg.sender] = true;
        referralCodeCounter = 0;
        gnomeToken = IGNOME(gnome);
    }

    // Modifier to restrict access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    event NewSignUp(address indexed user, string referralCode);
    event ReferralCodeGenerated(address indexed user, string referralCode);

    function setMiContracts(address _gnome) external onlyOwner {
        gnomeToken = IGNOME(_gnome);
    }

    function setmintPriceETH(uint256 price) public onlyOwner {
        mintPriceETHReferral = price;
    }

    function setmintToken(bool isETH) public onlyOwner {
        mintETH = isETH;
    }

    function setReferralPriceGNOME(uint256 newPrice) public onlyOwner {
        referralPriceGnome = newPrice;
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IGNOME(token).balanceOf(address(this));
        IGNOME(token).transfer(msg.sender, balance);
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

    function signUpReferral(string memory code, address sender, uint gnomeAmount) public onlyAuth {
        require(!isSignedUp[sender], "Already signed up");
        require(!usedReferralCodes[code], "Referral code already used");
        require(referralCodeToAddress[code] != address(0), "Invalid referral code");

        isSignedUp[sender] = true;
        usedReferralCodes[code] = true;
        referedBy[sender] = referralCodeToAddress[code];
        deleteReferralCode(referralCodeToAddress[code], code);
        if (mintETH) {
            address currentReferrer = sender;
            uint256 remainingReward = mintPriceETHReferral * gnomeAmount;
            uint256 reward = calculateReward(remainingReward, 0);
            referralRewardsETH[currentReferrer] += reward;
            currentReferrer = referedBy[currentReferrer];
        } else {
            //require(gnomeToken.balanceOf(sender) >= referralPriceGnome, "Not enough gnome tokens");
            //gnomeToken.transferFrom(sender, address(this), referralPriceGnome);
            if (referedBy[sender] != address(0)) {
                address currentReferrer = sender;
                uint256 remainingReward = referralPriceGnome * gnomeAmount;
                uint256 reward = calculateReward(remainingReward, 0);
                referralRewardsGNOME[currentReferrer] += reward;
                currentReferrer = referedBy[currentReferrer];
            }
        }

        //generates 10 referal codes
        for (uint256 i = 0; i < 5; i++) {
            _generateReferralCode();
        }

        emit NewSignUp(msg.sender, code);
    }

    function generateReferralCode() public returns (string memory) {
        require(
            isSignedUp[msg.sender] || msg.sender == owner || msg.sender == address(this),
            "Not authorized to generate code"
        );
        if (msg.sender != owner) {
            require(gnomeToken.balanceOf(msg.sender) >= referralPriceGnome, "Not enough gnome tokens");
            gnomeToken.transferFrom(msg.sender, address(this), referralPriceGnome);
        }
        return _generateReferralCode();
    }

    function _generateReferralCode() internal returns (string memory) {
        referralCodeCounter++;
        bytes memory code = new bytes(6);

        for (uint256 i = 0; i < 6; i++) {
            uint256 rand = uint256(
                keccak256(abi.encodePacked(referralCodeCounter, block.difficulty, block.timestamp, i))
            );
            code[i] = CHARACTERS[rand % CHARACTERS_LENGTH];
        }

        string memory newCode = string(abi.encodePacked("gnome-BASE-", string(code)));
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

    function claimGNOME() public {
        uint256 reward = referralRewardsGNOME[msg.sender];
        require(reward > 0, "No rewards to claim");

        // Reset the user's referral reward balance
        referralRewardsGNOME[msg.sender] = 0;

        // Transfer the gnome tokens from the contract to the user
        require(gnomeToken.transfer(msg.sender, reward), "Transfer failed");
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

    function setIsAuth(address fren, bool isAuthorized) external onlyAuth {
        isAuth[fren] = isAuthorized;
    }

    function setOpen(bool _open) external onlyAuth {
        referralopen = _open;
    }

    function getTokenIdReferedBy(uint256 tokenId) public view returns (address) {
        return tokenIdReferedBy[tokenId];
    }

    function getReferedBy(address fren) public view returns (address) {
        return referedBy[fren];
    }

    // Additional functions like transferring ownership can be added if needed
}