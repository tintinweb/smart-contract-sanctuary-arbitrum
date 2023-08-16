// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

struct Token
{
    address tokenContract;
    string symbol;
    string name;
    uint decimals;
}

library Custom_ERC20 {

    function ETH() internal pure returns (Token memory)
    {
        return Token({
            tokenContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            symbol: "ETH",
            name: "ETH",
            decimals: 18
        });
    }
}

library TokenHelper {
    function get(address _tokenContract) internal view returns (Token memory)
    {
        if (_tokenContract == Custom_ERC20.ETH().tokenContract)
        {
            return Custom_ERC20.ETH();
        }
        else
        {
            ERC20 erc20 = ERC20(_tokenContract);
            require(erc20.decimals() <= 18, "This decimal is not supported");

            return Token({
                    tokenContract: _tokenContract,
                    symbol:erc20.symbol(),
                    name:erc20.name(),
                    decimals:erc20.decimals()
                });
        }
    }
}

struct TokenMap
{
    mapping(address => Token) data;
    address[] keys;
    uint size;
}

library TokenMapHelper {

    function insert(TokenMap storage tokenMap, address __tokenContract) internal returns (bool)
    {
        if (tokenMap.data[__tokenContract].tokenContract != address(0))
            return false;
        else
        {
            Token memory token = TokenHelper.get(__tokenContract);
            tokenMap.data[__tokenContract] = Token(__tokenContract, token.symbol, token.name, token.decimals);
            tokenMap.size++;
            {
                bool added = false;
                for (uint i=0; i<tokenMap.keys.length;i++)
                {
                    if (tokenMap.keys[i] == address(0))
                    {
                        tokenMap.keys[i] = __tokenContract;
                        added = true;
                        break;
                    }
                }
                if (added == false)
                {
                    tokenMap.keys.push(__tokenContract);
                }
            }
            return true;
        }
     }

    function remove(TokenMap storage tokenMap, address __tokenContract) internal returns (bool)
    {
        if (tokenMap.data[__tokenContract].tokenContract == address(0))
            return false;
        else
        {
            delete tokenMap.data[__tokenContract];
            tokenMap.size--;

            for (uint i=0; i<tokenMap.keys.length; i++)
            {
                if (tokenMap.keys[i] == __tokenContract)
                {
                    tokenMap.keys[i] = address(0);
                }
            }

            while (true)
            {
                if (tokenMap.keys.length == 0)
                    break;
                if (tokenMap.keys[tokenMap.keys.length-1] != address(0))
                    break;
                tokenMap.keys.pop();
            }

            return true;
        }
    }

    function get(TokenMap storage tokenMap, address __tokenContract) internal view returns (Token memory)
    {
        return tokenMap.data[__tokenContract];
    }

    function length(TokenMap storage tokenMap) internal view returns (uint256)
    {
        return tokenMap.keys.length;
    }

    function toList(TokenMap storage tokenMap, uint256 start, uint256 end) internal view returns (address[] memory list)
    {
        end = tokenMap.keys.length >= end ? end : tokenMap.keys.length;
        list = new address[](end-start);
        uint index = 0;
        for (uint256 i=start; i<end; i++)
        {
            list[index] = tokenMap.keys[i];
            index++;
        }
        return list;
    }
}

contract TokenManager {

    // 交易对
    TokenMap tokenMap;

    address private _owner;
    mapping (address => bool) private _admins;

    event Insert(address indexed token, bytes symbol, bytes name, uint decimals);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
    }

    function setAdmin(address __admin, bool isTrue) external onlyOwner
    {
        _admins[__admin] = isTrue;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender] == true || _owner == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    function insertToken(address __token) external onlyAdmin returns (bool)
    {
        bool res = TokenMapHelper.insert(tokenMap, __token);
        if (res)
        {
            Token memory t = TokenMapHelper.get(tokenMap, __token);
            emit Insert(__token, bytes(t.symbol), bytes(t.name), t.decimals);
        }
        return res;
    }
 
    function getToken(address __tokenContract) external view returns (Token memory)
    {
        return TokenMapHelper.get(tokenMap, __tokenContract);
    }
}