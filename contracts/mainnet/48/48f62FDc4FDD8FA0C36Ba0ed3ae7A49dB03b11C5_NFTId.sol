pragma solidity ^0.8.20;

contract NFTId {
    CamelotPair public camelotPair;
    uint256 public original = 0;
    address public token404;
    uint public  multiple = 2;
    mapping(address => bool) rootList;

    constructor(address _pair, address _token404) {
        camelotPair = CamelotPair(_pair);
        token404 = _token404;
        rootList[msg.sender] = true;
    }

    function changeTokenAddress(address _pair, address _token404,uint _multiple) external {
        require(rootList[msg.sender], "address errot");
        camelotPair = CamelotPair(_pair);
        token404 = _token404;
        multiple = _multiple;
    }
    function setOriginal(uint _original)external {
        require(rootList[msg.sender], "address errot");
        original = _original;
    }

    function makeNFTType(uint256 id, uint256 amount)
        external 
        view
        returns (uint256)
    {
        require(rootList[msg.sender], "address errot");
        uint256 newPrice = getAmountPrice();
        if(newPrice < original * multiple){
            return 7;
        }

        uint8 seed = uint8(bytes1(keccak256(abi.encodePacked(id))));
        if (amount < (1000 * (10**18))) {
            return 7;
        } else if (amount <= 3000 * (10**18)) {
            if (seed <= 156) {
                return 7;
            } else {
                return 6;
            }
        } else if (amount < 5000 * (10**18)) {
            if (seed <= 156) {
                return 7;
            } else if (seed <= 218) {
                return 6;
            } else {
                return 5;
            }
        } else if (amount < 7000 * (10**18)) {
            if (seed <= 98) {
                return 7;
            } else if (seed <= 158) {
                return 6;
            } else if (seed <= 218) {
                return 5;
            } else {
                return 4;
            }
        } else if (amount < 9999 * (10**18)) {
            if (seed <= 75) {
                return 7;
            } else if (seed <= 135) {
                return 6;
            } else if (seed <= 195) {
                return 5;
            } else if (seed <= 231) {
                return 4;
            } else {
                return 3;
            }
        } else {
            if (seed <= 30) {
                return 7;
            } else if (seed <= 127) {
                return 6;
            } else if (seed <= 188) {
                return 5;
            } else if (seed <= 225) {
                return 4;
            } else if (seed <= 247) {
                return 3;
            } else if (seed <= 254) {
                return 2;
            } else {
                return 1;
            }
        }
    }

    function getAmountPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, , ) = camelotPair.getReserves();
        uint256 tokenReserve;
        uint256 ethReserve;

        if (camelotPair.token0() == token404) {
            tokenReserve = reserve0;
            ethReserve = reserve1;
        } else {
            tokenReserve = reserve1;
            ethReserve = reserve0;
        }
        return (10**18 * ethReserve) / tokenReserve;
    }
}

contract CamelotPair {
    address public token0;
    address public token1;

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint16 _token0FeePercent,
            uint16 _token1FeePercent
        )
    {}
}