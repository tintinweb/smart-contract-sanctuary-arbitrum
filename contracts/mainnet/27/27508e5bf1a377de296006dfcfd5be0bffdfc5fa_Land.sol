/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

pragma solidity ^0.8.9;

contract Land {
    uint256 constant MAX = 1000;
    uint256 constant PRICE = 0.05 ether;
    uint256 public supply;
    address public owner;
    bool lock;
    struct Content {
        bool sell;
        string twitter;
        string website;
        string discord;
    }
    mapping(uint256 => Content) public content;
    mapping(uint256 => address) public contentOnwer;
    modifier checkLock() {
        require(!lock, "locked");
        lock = true;
        _;
        lock = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function purchasing(
        uint256[] calldata _position,
        Content[] calldata _content
    ) public payable checkLock {
        require(supply + _position.length <= MAX);
        require(_position.length == _content.length, "mismatch");
        require(
            msg.value >= _position.length * PRICE,
            "insufficient purchasing power"
        );
        for (uint256 i = 0; i < _position.length; i++) {
            require(
                !content[_position[i]].sell && _position[i] < MAX,
                "isSell"
            );
            require(
                bytes(_content[i].twitter).length <= 100 &&
                    bytes(_content[i].website).length <= 100 &&
                    bytes(_content[i].discord).length <= 100
            );
            content[_position[i]] = _content[i];
            content[_position[i]].sell = true;
            contentOnwer[_position[i]] = msg.sender;
        }
        supply = supply + _position.length;
    }

    function updateContent(uint256 _position, Content calldata _content)
        public
    {
        require(contentOnwer[_position] == msg.sender, "invalid sender");
        require(
            bytes(_content.twitter).length <= 100 &&
                bytes(_content.website).length <= 100 &&
                bytes(_content.discord).length <= 100
        );
        content[_position] = _content;
        content[_position].sell = true;
    }

    function transfer(uint256 _position, address _to) public {
        require(contentOnwer[_position] == msg.sender, "invalid sender");
        contentOnwer[_position] = _to;
    }

    function showLand(uint256 _start, uint256 _end)
        external
        view
        returns (Content[] memory)
    {
        require(_end > _start && _end <= MAX);
        Content[] memory _content = new Content[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _content[i - _start] = content[i];
        }
        return _content;
    }

    function withdraw() public {
        require(msg.sender == owner, "invalid sender");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}