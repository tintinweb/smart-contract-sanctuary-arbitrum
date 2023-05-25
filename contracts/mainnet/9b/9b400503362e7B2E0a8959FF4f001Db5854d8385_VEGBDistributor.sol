interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;
}

interface IStakedDistributor {
    function addReward(address token, uint256 amount) external returns (uint256 _shareIndex);
}

contract VEGBDistributor {

    IStakedDistributor public stakedDistributor;
    IERC20 public gb;
    address public admin;

    modifier onlyAdmin() {
        require(admin == msg.sender, "caller is not the admin!");
        _;
    }

    constructor(IStakedDistributor stakedDistributor_, IERC20 gb_, address admin_) {
        stakedDistributor = stakedDistributor_;
        gb = gb_;
        gb.approve(address(stakedDistributor_), type(uint).max);
        admin = admin_;
    }

    function addReward(address token, uint256 amount) external onlyAdmin {
        stakedDistributor.addReward(token, amount);
    }
}