/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClips {
    function mintClips() payable external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenBot{
    bytes32 byteCode;
    uint256 n = 0;

    constructor() {
    }

    function batchMint(address addr, address toAddr, uint cnt) external payable {
        // require(
        //     msg.sender == deployer,
        //     "Only deployer can call this function."
        // );
        require(msg.value >= 0.003 ether, "not enough ehter");
        
        uint from = n;
        uint to = from + cnt;
        createProxies(from, to);
        n = to;

        uint256 _value = msg.value/cnt;

        for (uint256 i = from; i < to; ) {
            address proxy = proxyFor(msg.sender, i);
            TokenBot(proxy).callback{value: _value}(proxy, addr, toAddr);

            unchecked {
                ++i;
            }
        }

        _value = 0;
    }


    function callback(
        address sender,
        address target,
        address to
    ) external payable {

        IClips(target).mintClips{value: msg.value}();
        uint256 balance = IClips(target).balanceOf(sender);
        IClips(target).transfer(
            to,
            balance
        );

    }

    function createProxies(uint256 from, uint256 to) internal {
        require(from < to);
        bytes memory miniProxy = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        byteCode = keccak256(abi.encodePacked(miniProxy));
        address proxy;
        for (uint256 i = from; i < to; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            assembly {
                proxy := create2(0, add(miniProxy, 32), mload(miniProxy), salt)
            }
        }
    }

    function proxyFor(address sender, uint256 i)
        public
        view
        returns (address proxy)
    {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"ff", address(this), salt, byteCode)
                    )
                )
            )
        );
    }
}