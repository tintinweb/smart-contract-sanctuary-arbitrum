pragma solidity ^0.8.15;


import "./MarketTradingControl.sol";
import "./ApedToken.sol";

interface DAIInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Vault {

    //contracts
    MarketTradingControl immutable marketTradingControl;
    ApedToken immutable apedToken;

    uint internal vaultReserveBalance;
    uint internal vaultTokenBalance;
    mapping(address => uint) tradersAccountBalance;

    address private apedAdmin;
    address[] public traders;

    address public DAIAddress;
    DAIInterface DAI = DAIInterface(DAIAddress);

    constructor(MarketTradingControl _tradingControl, ApedToken _apedToken, address _daiAddress)  {
        marketTradingControl = _tradingControl;
        apedToken = _apedToken;
        DAIAddress = _daiAddress;

    }


    function deposit(uint _amount) public {
          DAI.approve(address(this), _amount);
          DAI.transferFrom(msg.sender, address(this), _amount);

          vaultReserveBalance = vaultReserveBalance + _amount;
          tradersAccountBalance[msg.sender] = tradersAccountBalance[msg.sender] + _amount;
          traders.push(msg.sender); // check if traders have been added 

    }

    function withdraw(uint _amount) public {

        tradersAccountBalance[msg.sender] = tradersAccountBalance[msg.sender] - _amount;
        vaultReserveBalance = vaultReserveBalance - _amount;

        DAI.transferFrom(address(this), msg.sender, _amount);

    }

    function openMarketPriceOrder(
                bytes32 _pair, 
                uint256 orderType, 
                uint _leverageAmount, 
                uint _collateral, 
                uint _takeProfit, 
                uint _stopLoss) public {

        marketTradingControl.openMarketOrder(_pair, orderType, _leverageAmount, _collateral, _takeProfit, _stopLoss);
        tradersAccountBalance[msg.sender] = tradersAccountBalance[msg.sender] - _collateral;

    }

    function closeOrder(uint _tradeId) public {
        uint profit = marketTradingControl.closeMarketOrder(_tradeId, msg.sender);

        if (profit > 0) {
            tradersAccountBalance[msg.sender] = tradersAccountBalance[msg.sender] + profit;
        } else {
            tradersAccountBalance[msg.sender] = tradersAccountBalance[msg.sender] - profit;
            vaultBalancing();
        }


    }


    function vaultBalancing() internal {
       require(vaultReserveBalance >= 200000);

       uint curveReserveBalance = DAI.balanceOf(address(apedToken));
       uint burnThreshold = percent(90, curveReserveBalance);
       uint mintThreshold = percent(120, curveReserveBalance);
        

       if (vaultReserveBalance <= burnThreshold ) {
        // calculate required APED token amount to get 10% amount of DAI from curve
        uint reserveTokenRequest = percent(10, curveReserveBalance);
        uint apedTokenRequired = apedToken.calculateBurnAmountRequired(reserveTokenRequest);
        
        // need to check if vault has equal or more aped Token required
        uint reserveToken = apedToken.burn(apedTokenRequired);

       } else if (vaultReserveBalance >= mintThreshold) {

          uint excessVaultBalance = vaultReserveBalance - 200000;        
          uint token = apedToken.mint(excessVaultBalance);
          vaultTokenBalance = vaultTokenBalance + token;

       }

    }

    function percent(uint a, uint b) internal pure returns(uint) {
      uint c = a*b;
      uint integer = c/100;
      uint fractional = c%100;
      return integer;
    }

    function checkReserveVaultBalance() public view returns (uint) {
        require(apedAdmin == msg.sender);
        return DAI.balanceOf(address(this));

    }

    function checkTokenVaultBalance() public view returns (uint) {
        require(apedAdmin == msg.sender);
        return vaultTokenBalance;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Power{
    using SafeMath for uint256;


    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    // Auto-generated via 'PrintIntScalingFactors.py'
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    // Auto-generated via 'PrintLn2ScalingFactors.py'
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    // Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    uint256 private constant OPT_LOG_MAX_VAL =
        0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL =
        0x800000000000000000000000000000000;

    // Auto-generated via 'PrintLambertFactors.py'
    uint256 private constant LAMBERT_CONV_RADIUS =
        0x002f16ac6c59de6f8d5d6f63c1482a7c86;
    uint256 private constant LAMBERT_POS2_SAMPLE =
        0x0003060c183060c183060c183060c18306;
    uint256 private constant LAMBERT_POS2_MAXVAL =
        0x01af16ac6c59de6f8d5d6f63c1482a7c80;
    uint256 private constant LAMBERT_POS3_MAXVAL =
        0x6b22d43e72c326539cceeef8bb48f255ff;

    // Auto-generated via 'PrintWeightFactors.py'
    uint256 private constant MAX_UNF_WEIGHT =
        0x10c6f7a0b5ed8d36b4c7f34938583621fafc8b0079a2834d26fa3fcc9ea9;

    // Auto-generated via 'PrintMaxExpArray.py'
    uint256[128] private maxExpArray;

    function initMaxExpArray() public {
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    // Auto-generated via 'PrintLambertArray.py'
    uint256[128] private lambertArray;

    function initLambertArray() public {
        lambertArray[0] = 0x60e393c68d20b1bd09deaabc0373b9c5;
        lambertArray[1] = 0x5f8f46e4854120989ed94719fb4c2011;
        lambertArray[2] = 0x5e479ebb9129fb1b7e72a648f992b606;
        lambertArray[3] = 0x5d0bd23fe42dfedde2e9586be12b85fe;
        lambertArray[4] = 0x5bdb29ddee979308ddfca81aeeb8095a;
        lambertArray[5] = 0x5ab4fd8a260d2c7e2c0d2afcf0009dad;
        lambertArray[6] = 0x5998b31359a55d48724c65cf09001221;
        lambertArray[7] = 0x5885bcad2b322dfc43e8860f9c018cf5;
        lambertArray[8] = 0x577b97aa1fe222bb452fdf111b1f0be2;
        lambertArray[9] = 0x5679cb5e3575632e5baa27e2b949f704;
        lambertArray[10] = 0x557fe8241b3a31c83c732f1cdff4a1c5;
        lambertArray[11] = 0x548d868026504875d6e59bbe95fc2a6b;
        lambertArray[12] = 0x53a2465ce347cf34d05a867c17dd3088;
        lambertArray[13] = 0x52bdce5dcd4faed59c7f5511cf8f8acc;
        lambertArray[14] = 0x51dfcb453c07f8da817606e7885f7c3e;
        lambertArray[15] = 0x5107ef6b0a5a2be8f8ff15590daa3cce;
        lambertArray[16] = 0x5035f241d6eae0cd7bacba119993de7b;
        lambertArray[17] = 0x4f698fe90d5b53d532171e1210164c66;
        lambertArray[18] = 0x4ea288ca297a0e6a09a0eee240e16c85;
        lambertArray[19] = 0x4de0a13fdcf5d4213fc398ba6e3becde;
        lambertArray[20] = 0x4d23a145eef91fec06b06140804c4808;
        lambertArray[21] = 0x4c6b5430d4c1ee5526473db4ae0f11de;
        lambertArray[22] = 0x4bb7886c240562eba11f4963a53b4240;
        lambertArray[23] = 0x4b080f3f1cb491d2d521e0ea4583521e;
        lambertArray[24] = 0x4a5cbc96a05589cb4d86be1db3168364;
        lambertArray[25] = 0x49b566d40243517658d78c33162d6ece;
        lambertArray[26] = 0x4911e6a02e5507a30f947383fd9a3276;
        lambertArray[27] = 0x487216c2b31be4adc41db8a8d5cc0c88;
        lambertArray[28] = 0x47d5d3fc4a7a1b188cd3d788b5c5e9fc;
        lambertArray[29] = 0x473cfce4871a2c40bc4f9e1c32b955d0;
        lambertArray[30] = 0x46a771ca578ab878485810e285e31c67;
        lambertArray[31] = 0x4615149718aed4c258c373dc676aa72d;
        lambertArray[32] = 0x4585c8b3f8fe489c6e1833ca47871384;
        lambertArray[33] = 0x44f972f174e41e5efb7e9d63c29ce735;
        lambertArray[34] = 0x446ff970ba86d8b00beb05ecebf3c4dc;
        lambertArray[35] = 0x43e9438ec88971812d6f198b5ccaad96;
        lambertArray[36] = 0x436539d11ff7bea657aeddb394e809ef;
        lambertArray[37] = 0x42e3c5d3e5a913401d86f66db5d81c2c;
        lambertArray[38] = 0x4264d2395303070ea726cbe98df62174;
        lambertArray[39] = 0x41e84a9a593bb7194c3a6349ecae4eea;
        lambertArray[40] = 0x416e1b785d13eba07a08f3f18876a5ab;
        lambertArray[41] = 0x40f6322ff389d423ba9dd7e7e7b7e809;
        lambertArray[42] = 0x40807cec8a466880ecf4184545d240a4;
        lambertArray[43] = 0x400cea9ce88a8d3ae668e8ea0d9bf07f;
        lambertArray[44] = 0x3f9b6ae8772d4c55091e0ed7dfea0ac1;
        lambertArray[45] = 0x3f2bee253fd84594f54bcaafac383a13;
        lambertArray[46] = 0x3ebe654e95208bb9210c575c081c5958;
        lambertArray[47] = 0x3e52c1fc5665635b78ce1f05ad53c086;
        lambertArray[48] = 0x3de8f65ac388101ddf718a6f5c1eff65;
        lambertArray[49] = 0x3d80f522d59bd0b328ca012df4cd2d49;
        lambertArray[50] = 0x3d1ab193129ea72b23648a161163a85a;
        lambertArray[51] = 0x3cb61f68d32576c135b95cfb53f76d75;
        lambertArray[52] = 0x3c5332d9f1aae851a3619e77e4cc8473;
        lambertArray[53] = 0x3bf1e08edbe2aa109e1525f65759ef73;
        lambertArray[54] = 0x3b921d9cff13fa2c197746a3dfc4918f;
        lambertArray[55] = 0x3b33df818910bfc1a5aefb8f63ae2ac4;
        lambertArray[56] = 0x3ad71c1c77e34fa32a9f184967eccbf6;
        lambertArray[57] = 0x3a7bc9abf2c5bb53e2f7384a8a16521a;
        lambertArray[58] = 0x3a21dec7e76369783a68a0c6385a1c57;
        lambertArray[59] = 0x39c9525de6c9cdf7c1c157ca4a7a6ee3;
        lambertArray[60] = 0x39721bad3dc85d1240ff0190e0adaac3;
        lambertArray[61] = 0x391c324344d3248f0469eb28dd3d77e0;
        lambertArray[62] = 0x38c78df7e3c796279fb4ff84394ab3da;
        lambertArray[63] = 0x387426ea4638ae9aae08049d3554c20a;
        lambertArray[64] = 0x3821f57dbd2763256c1a99bbd2051378;
        lambertArray[65] = 0x37d0f256cb46a8c92ff62fbbef289698;
        lambertArray[66] = 0x37811658591ffc7abdd1feaf3cef9b73;
        lambertArray[67] = 0x37325aa10e9e82f7df0f380f7997154b;
        lambertArray[68] = 0x36e4b888cfb408d873b9a80d439311c6;
        lambertArray[69] = 0x3698299e59f4bb9de645fc9b08c64cca;
        lambertArray[70] = 0x364ca7a5012cb603023b57dd3ebfd50d;
        lambertArray[71] = 0x36022c928915b778ab1b06aaee7e61d4;
        lambertArray[72] = 0x35b8b28d1a73dc27500ffe35559cc028;
        lambertArray[73] = 0x357033e951fe250ec5eb4e60955132d7;
        lambertArray[74] = 0x3528ab2867934e3a21b5412e4c4f8881;
        lambertArray[75] = 0x34e212f66c55057f9676c80094a61d59;
        lambertArray[76] = 0x349c66289e5b3c4b540c24f42fa4b9bb;
        lambertArray[77] = 0x34579fbbd0c733a9c8d6af6b0f7d00f7;
        lambertArray[78] = 0x3413bad2e712288b924b5882b5b369bf;
        lambertArray[79] = 0x33d0b2b56286510ef730e213f71f12e9;
        lambertArray[80] = 0x338e82ce00e2496262c64457535ba1a1;
        lambertArray[81] = 0x334d26a96b373bb7c2f8ea1827f27a92;
        lambertArray[82] = 0x330c99f4f4211469e00b3e18c31475ea;
        lambertArray[83] = 0x32ccd87d6486094999c7d5e6f33237d8;
        lambertArray[84] = 0x328dde2dd617b6665a2e8556f250c1af;
        lambertArray[85] = 0x324fa70e9adc270f8262755af5a99af9;
        lambertArray[86] = 0x32122f443110611ca51040f41fa6e1e3;
        lambertArray[87] = 0x31d5730e42c0831482f0f1485c4263d8;
        lambertArray[88] = 0x31996ec6b07b4a83421b5ebc4ab4e1f1;
        lambertArray[89] = 0x315e1ee0a68ff46bb43ec2b85032e876;
        lambertArray[90] = 0x31237fe7bc4deacf6775b9efa1a145f8;
        lambertArray[91] = 0x30e98e7f1cc5a356e44627a6972ea2ff;
        lambertArray[92] = 0x30b04760b8917ec74205a3002650ec05;
        lambertArray[93] = 0x3077a75c803468e9132ce0cf3224241d;
        lambertArray[94] = 0x303fab57a6a275c36f19cda9bace667a;
        lambertArray[95] = 0x3008504beb8dcbd2cf3bc1f6d5a064f0;
        lambertArray[96] = 0x2fd19346ed17dac61219ce0c2c5ac4b0;
        lambertArray[97] = 0x2f9b7169808c324b5852fd3d54ba9714;
        lambertArray[98] = 0x2f65e7e711cf4b064eea9c08cbdad574;
        lambertArray[99] = 0x2f30f405093042ddff8a251b6bf6d103;
        lambertArray[100] = 0x2efc931a3750f2e8bfe323edfe037574;
        lambertArray[101] = 0x2ec8c28e46dbe56d98685278339400cb;
        lambertArray[102] = 0x2e957fd933c3926d8a599b602379b851;
        lambertArray[103] = 0x2e62c882c7c9ed4473412702f08ba0e5;
        lambertArray[104] = 0x2e309a221c12ba361e3ed695167feee2;
        lambertArray[105] = 0x2dfef25d1f865ae18dd07cfea4bcea10;
        lambertArray[106] = 0x2dcdcee821cdc80decc02c44344aeb31;
        lambertArray[107] = 0x2d9d2d8562b34944d0b201bb87260c83;
        lambertArray[108] = 0x2d6d0c04a5b62a2c42636308669b729a;
        lambertArray[109] = 0x2d3d6842c9a235517fc5a0332691528f;
        lambertArray[110] = 0x2d0e402963fe1ea2834abc408c437c10;
        lambertArray[111] = 0x2cdf91ae602647908aff975e4d6a2a8c;
        lambertArray[112] = 0x2cb15ad3a1eb65f6d74a75da09a1b6c5;
        lambertArray[113] = 0x2c8399a6ab8e9774d6fcff373d210727;
        lambertArray[114] = 0x2c564c4046f64edba6883ca06bbc4535;
        lambertArray[115] = 0x2c2970c431f952641e05cb493e23eed3;
        lambertArray[116] = 0x2bfd0560cd9eb14563bc7c0732856c18;
        lambertArray[117] = 0x2bd1084ed0332f7ff4150f9d0ef41a2c;
        lambertArray[118] = 0x2ba577d0fa1628b76d040b12a82492fb;
        lambertArray[119] = 0x2b7a5233cd21581e855e89dc2f1e8a92;
        lambertArray[120] = 0x2b4f95cd46904d05d72bdcde337d9cc7;
        lambertArray[121] = 0x2b2540fc9b4d9abba3faca6691914675;
        lambertArray[122] = 0x2afb5229f68d0830d8be8adb0a0db70f;
        lambertArray[123] = 0x2ad1c7c63a9b294c5bc73a3ba3ab7a2b;
        lambertArray[124] = 0x2aa8a04ac3cbe1ee1c9c86361465dbb8;
        lambertArray[125] = 0x2a7fda392d725a44a2c8aeb9ab35430d;
        lambertArray[126] = 0x2a57741b18cde618717792b4faa216db;
        lambertArray[127] = 0x2a2f6c81f5d84dd950a35626d6d5503a;
    }

    /**
     * @dev General Description:
     *     Determine a value of precision.
     *     Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
     *     Return the result along with the precision used.
     *
     * Detailed Description:
     *     Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
     *     The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
     *     The larger "precision" is, the more accurately this value represents the real value.
     *     However, the larger "precision" is, the more bits are required in order to store this value.
     *     And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
     *     This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     *     Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     *     This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     *     This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
     *     Since we rely on unsigned-integer arithmetic and "base < 1" ==> "log(base) < 0", this function does not support "_baseN < _baseD".
     */
    function power(
        uint256 _baseN,
        uint256 _baseD,
        uint32 _expN,
        uint32 _expD
    ) public view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = (_baseN * FIXED_1) / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = (baseLog * _expN) / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (
                generalExp(
                    baseLogTimesExp >> (MAX_PRECISION - precision),
                    precision
                ),
                precision
            );
        }
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1.
     * This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
    }

    /**
     * @dev computes the largest integer smaller than or equal to the binary logarithm of the input.
     */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
     * @dev the global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     */
    function findPositionInMaxExpArray(uint256 _x)
        internal
        view
        returns (uint8 pos)
    {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x) lo = mid;
            else hi = mid;
        }

        if (maxExpArray[hi] >= _x) return pos = hi;
        if (maxExpArray[lo] >= _x) return pos = lo;

        require(false);
    }

    /**
     * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision)
        internal
        pure
        returns (uint256)
    {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return
            res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1
     * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalLog.py'
     * Detailed description:
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        res +=
            (z * (0x100000000000000000000000000000000 - y)) /
            0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        res +=
            (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) /
            0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        res +=
            (z * (0x099999999999999999999999999999999 - y)) /
            0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        res +=
            (z * (0x092492492492492492492492492492492 - y)) /
            0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        res +=
            (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) /
            0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        res +=
            (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) /
            0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        res +=
            (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) /
            0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        res +=
            (z * (0x088888888888888888888888888888888 - y)) /
            0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * @dev computes e ^ (x / FIXED_1) * FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res =
                (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) /
                0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res =
                (res * 0x18ebef9eac820ae8682b9793ac6d1e778) /
                0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res =
                (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) /
                0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res =
                (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) /
                0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res =
                (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) /
                0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res =
                (res * 0x00960aadc109e7a3bf4578099615711d7) /
                0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res =
                (res * 0x0002bf84208204f5977f9a8cf01fdc307) /
                0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     */
    function lowerStake(uint256 _x) internal view returns (uint256 pos) {
        if (_x <= LAMBERT_CONV_RADIUS) return pos = lambertPos1(_x);
        if (_x <= LAMBERT_POS2_MAXVAL) return pos = lambertPos2(_x);
        if (_x <= LAMBERT_POS3_MAXVAL) return pos = lambertPos3(_x);
        require(false);
    }

    /**
     * @dev computes W(-x / FIXED_1) / (-x / FIXED_1) * FIXED_1
     */
    function higherStake(uint256 _x) internal pure returns (uint256) {
        if (_x <= LAMBERT_CONV_RADIUS) return lambertNeg1(_x);
        return (FIXED_1 * FIXED_1) / _x;
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     * input range: 1 <= x <= 1 / e * FIXED_1
     * auto-generated via 'PrintFunctionLambertPos1.py'
     */
    function lambertPos1(uint256 _x) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = (FIXED_1 - _x) * 0xde1bc4d19efcac82445da75b00000000; // x^(1-1) * (34! * 1^(1-1) / 1!) - x^(2-1) * (34! * 2^(2-1) / 2!)

        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000014d29a73a6e7b02c3668c7b0880000000; // add x^(03-1) * (34! * 03^(03-1) / 03!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000000002504a0cd9a7f7215b60f9be4800000000; // sub x^(04-1) * (34! * 04^(04-1) / 04!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000000484d0a1191c0ead267967c7a4a0000000; // add x^(05-1) * (34! * 05^(05-1) / 05!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00000000095ec580d7e8427a4baf26a90a00000000; // sub x^(06-1) * (34! * 06^(06-1) / 06!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000001440b0be1615a47dba6e5b3b1f10000000; // add x^(07-1) * (34! * 07^(07-1) / 07!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x000000002d207601f46a99b4112418400000000000; // sub x^(08-1) * (34! * 08^(08-1) / 08!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000066ebaac4c37c622dd8288a7eb1b2000000; // add x^(09-1) * (34! * 09^(09-1) / 09!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00000000ef17240135f7dbd43a1ba10cf200000000; // sub x^(10-1) * (34! * 10^(10-1) / 10!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000233c33c676a5eb2416094a87b3657000000; // add x^(11-1) * (34! * 11^(11-1) / 11!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000000541cde48bc0254bed49a9f8700000000000; // sub x^(12-1) * (34! * 12^(12-1) / 12!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000cae1fad2cdd4d4cb8d73abca0d19a400000; // add x^(13-1) * (34! * 13^(13-1) / 13!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000001edb2aa2f760d15c41ceedba956400000000; // sub x^(14-1) * (34! * 14^(14-1) / 14!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000004ba8d20d2dabd386c9529659841a2e200000; // add x^(15-1) * (34! * 15^(15-1) / 15!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x000000bac08546b867cdaa20000000000000000000; // sub x^(16-1) * (34! * 16^(16-1) / 16!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000001cfa8e70c03625b9db76c8ebf5bbf24820000; // add x^(17-1) * (34! * 17^(17-1) / 17!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x000004851d99f82060df265f3309b26f8200000000; // sub x^(18-1) * (34! * 18^(18-1) / 18!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000b550d19b129d270c44f6f55f027723cbb0000; // add x^(19-1) * (34! * 19^(19-1) / 19!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00001c877dadc761dc272deb65d4b0000000000000; // sub x^(20-1) * (34! * 20^(20-1) / 20!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000048178ece97479f33a77f2ad22a81b64406c000; // add x^(21-1) * (34! * 21^(21-1) / 21!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000b6ca8268b9d810fedf6695ef2f8a6c00000000; // sub x^(22-1) * (34! * 22^(22-1) / 22!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0001d0e76631a5b05d007b8cb72a7c7f11ec36e000; // add x^(23-1) * (34! * 23^(23-1) / 23!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0004a1c37bd9f85fd9c6c780000000000000000000; // sub x^(24-1) * (34! * 24^(24-1) / 24!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000bd8369f1b702bf491e2ebfcee08250313b65400; // add x^(25-1) * (34! * 25^(25-1) / 25!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x001e5c7c32a9f6c70ab2cb59d9225764d400000000; // sub x^(26-1) * (34! * 26^(26-1) / 26!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x004dff5820e165e910f95120a708e742496221e600; // add x^(27-1) * (34! * 27^(27-1) / 27!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00c8c8f66db1fced378ee50e536000000000000000; // sub x^(28-1) * (34! * 28^(28-1) / 28!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0205db8dffff45bfa2938f128f599dbf16eb11d880; // add x^(29-1) * (34! * 29^(29-1) / 29!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x053a044ebd984351493e1786af38d39a0800000000; // sub x^(30-1) * (34! * 30^(30-1) / 30!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0d86dae2a4cc0f47633a544479735869b487b59c40; // add x^(31-1) * (34! * 31^(31-1) / 31!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x231000000000000000000000000000000000000000; // sub x^(32-1) * (34! * 32^(32-1) / 32!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x5b0485a76f6646c2039db1507cdd51b08649680822; // add x^(33-1) * (34! * 33^(33-1) / 33!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0xec983c46c49545bc17efa6b5b0055e242200000000; // sub x^(34-1) * (34! * 34^(34-1) / 34!)

        return res / 0xde1bc4d19efcac82445da75b00000000; // divide by 34!
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     * input range: LAMBERT_CONV_RADIUS + 1 <= x <= LAMBERT_POS2_MAXVAL
     */
    function lambertPos2(uint256 _x) internal view returns (uint256) {
        uint256 x = _x - LAMBERT_CONV_RADIUS - 1;
        uint256 i = x / LAMBERT_POS2_SAMPLE;
        uint256 a = LAMBERT_POS2_SAMPLE * i;
        uint256 b = LAMBERT_POS2_SAMPLE * (i + 1);
        uint256 c = lambertArray[i];
        uint256 d = lambertArray[i + 1];
        return (c * (b - x) + d * (x - a)) / LAMBERT_POS2_SAMPLE;
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     * input range: LAMBERT_POS2_MAXVAL + 1 <= x <= LAMBERT_POS3_MAXVAL
     */
    function lambertPos3(uint256 _x) internal pure returns (uint256) {
        uint256 l1 = _x < OPT_LOG_MAX_VAL ? optimalLog(_x) : generalLog(_x);
        uint256 l2 = l1 < OPT_LOG_MAX_VAL ? optimalLog(l1) : generalLog(l1);
        return ((l1 - l2 + (l2 * FIXED_1) / l1) * FIXED_1) / _x;
    }

    /**
     * @dev computes W(-x / FIXED_1) / (-x / FIXED_1) * FIXED_1
     * input range: 1 <= x <= 1 / e * FIXED_1
     * auto-generated via 'PrintFunctionLambertNeg1.py'
     */
    function lambertNeg1(uint256 _x) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000014d29a73a6e7b02c3668c7b0880000000; // add x^(03-1) * (34! * 03^(03-1) / 03!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000002504a0cd9a7f7215b60f9be4800000000; // add x^(04-1) * (34! * 04^(04-1) / 04!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000000484d0a1191c0ead267967c7a4a0000000; // add x^(05-1) * (34! * 05^(05-1) / 05!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000095ec580d7e8427a4baf26a90a00000000; // add x^(06-1) * (34! * 06^(06-1) / 06!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000001440b0be1615a47dba6e5b3b1f10000000; // add x^(07-1) * (34! * 07^(07-1) / 07!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000002d207601f46a99b4112418400000000000; // add x^(08-1) * (34! * 08^(08-1) / 08!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000066ebaac4c37c622dd8288a7eb1b2000000; // add x^(09-1) * (34! * 09^(09-1) / 09!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000ef17240135f7dbd43a1ba10cf200000000; // add x^(10-1) * (34! * 10^(10-1) / 10!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000233c33c676a5eb2416094a87b3657000000; // add x^(11-1) * (34! * 11^(11-1) / 11!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000541cde48bc0254bed49a9f8700000000000; // add x^(12-1) * (34! * 12^(12-1) / 12!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000cae1fad2cdd4d4cb8d73abca0d19a400000; // add x^(13-1) * (34! * 13^(13-1) / 13!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000001edb2aa2f760d15c41ceedba956400000000; // add x^(14-1) * (34! * 14^(14-1) / 14!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000004ba8d20d2dabd386c9529659841a2e200000; // add x^(15-1) * (34! * 15^(15-1) / 15!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000bac08546b867cdaa20000000000000000000; // add x^(16-1) * (34! * 16^(16-1) / 16!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000001cfa8e70c03625b9db76c8ebf5bbf24820000; // add x^(17-1) * (34! * 17^(17-1) / 17!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000004851d99f82060df265f3309b26f8200000000; // add x^(18-1) * (34! * 18^(18-1) / 18!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000b550d19b129d270c44f6f55f027723cbb0000; // add x^(19-1) * (34! * 19^(19-1) / 19!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00001c877dadc761dc272deb65d4b0000000000000; // add x^(20-1) * (34! * 20^(20-1) / 20!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000048178ece97479f33a77f2ad22a81b64406c000; // add x^(21-1) * (34! * 21^(21-1) / 21!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000b6ca8268b9d810fedf6695ef2f8a6c00000000; // add x^(22-1) * (34! * 22^(22-1) / 22!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0001d0e76631a5b05d007b8cb72a7c7f11ec36e000; // add x^(23-1) * (34! * 23^(23-1) / 23!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0004a1c37bd9f85fd9c6c780000000000000000000; // add x^(24-1) * (34! * 24^(24-1) / 24!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000bd8369f1b702bf491e2ebfcee08250313b65400; // add x^(25-1) * (34! * 25^(25-1) / 25!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x001e5c7c32a9f6c70ab2cb59d9225764d400000000; // add x^(26-1) * (34! * 26^(26-1) / 26!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x004dff5820e165e910f95120a708e742496221e600; // add x^(27-1) * (34! * 27^(27-1) / 27!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00c8c8f66db1fced378ee50e536000000000000000; // add x^(28-1) * (34! * 28^(28-1) / 28!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0205db8dffff45bfa2938f128f599dbf16eb11d880; // add x^(29-1) * (34! * 29^(29-1) / 29!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x053a044ebd984351493e1786af38d39a0800000000; // add x^(30-1) * (34! * 30^(30-1) / 30!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0d86dae2a4cc0f47633a544479735869b487b59c40; // add x^(31-1) * (34! * 31^(31-1) / 31!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x231000000000000000000000000000000000000000; // add x^(32-1) * (34! * 32^(32-1) / 32!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x5b0485a76f6646c2039db1507cdd51b08649680822; // add x^(33-1) * (34! * 33^(33-1) / 33!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0xec983c46c49545bc17efa6b5b0055e242200000000; // add x^(34-1) * (34! * 34^(34-1) / 34!)

        return res / 0xde1bc4d19efcac82445da75b00000000 + _x + FIXED_1; // divide by 34! and then add x^(2-1) * (34! * 2^(2-1) / 2!) + x^(1-1) * (34! * 1^(1-1) / 1!)
    }

    /**
     * @dev computes the weights based on "W(log(hi / lo) * tq / rp) * tq / rp", where "W" is a variation of the Lambert W function.
     */
    function balancedWeightsByStake(
        uint256 _hi,
        uint256 _lo,
        uint256 _tq,
        uint256 _rp,
        bool _lowerStake
    ) public view returns (uint32, uint32) {
        (_tq, _rp) = safeFactors(_tq, _rp);
        uint256 f = _hi.mul(FIXED_1) / _lo;
        uint256 g = f < OPT_LOG_MAX_VAL ? optimalLog(f) : generalLog(f);
        uint256 x = g.mul(_tq) / _rp;
        uint256 y = _lowerStake ? lowerStake(x) : higherStake(x);
        return normalizedWeights(y.mul(_tq), _rp.mul(FIXED_1));
    }

    /**
     * @dev reduces "a" and "b" while maintaining their ratio.
     */
    function safeFactors(uint256 _a, uint256 _b)
        public
        pure
        returns (uint256, uint256)
    {
        if (_a <= FIXED_2 && _b <= FIXED_2) return (_a, _b);
        if (_a < FIXED_2) return ((_a * FIXED_2) / _b, FIXED_2);
        if (_b < FIXED_2) return (FIXED_2, (_b * FIXED_2) / _a);
        uint256 c = _a > _b ? _a : _b;
        uint256 n = floorLog2(c / FIXED_1);
        return (_a >> n, _b >> n);
    }

    /**
     * @dev computes "MAX_WEIGHT * a / (a + b)" and "MAX_WEIGHT * b / (a + b)".
     */
    function normalizedWeights(uint256 _a, uint256 _b)
        public
        pure
        returns (uint32, uint32)
    {
        if (_a <= _b) return accurateWeights(_a, _b);
        (uint32 y, uint32 x) = accurateWeights(_b, _a);
        return (x, y);
    }

    /**
     * @dev computes "MAX_WEIGHT * a / (a + b)" and "MAX_WEIGHT * b / (a + b)", assuming that "a <= b".
     */
    function accurateWeights(uint256 _a, uint256 _b)
        public
        pure
        returns (uint32, uint32)
    {
        if (_a > MAX_UNF_WEIGHT) {
            uint256 c = _a / (MAX_UNF_WEIGHT + 1) + 1;
            _a /= c;
            _b /= c;
        }
        uint256 x = roundDiv(_a * MAX_WEIGHT, _a.add(_b));
        uint256 y = MAX_WEIGHT - x;
        return (uint32(x), uint32(y));
    }

    /**
     * @dev computes the nearest integer to a given quotient without overflowing or underflowing.
     */
    function roundDiv(uint256 _n, uint256 _d) internal pure returns (uint256) {
        return _n / _d + (_n % _d) / (_d - _d / 2);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface Pricefeed {
    function price() external view returns (uint);
}

contract PricefeedInterface is Pricefeed {
    function price() external view returns (uint) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    Bancor Formula interface
*/
interface IBancorFormula {
    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function crossReserveTargetAmount(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function fundSupplyAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function liquidateReserveAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function balancedWeights(
        uint256 _primaryReserveStakedBalance,
        uint256 _primaryReserveBalance,
        uint256 _secondaryReserveBalance,
        uint256 _reserveRateNumerator,
        uint256 _reserveRateDenominator
    ) external view returns (uint32, uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../interface/IBancorFormula.sol";
import "../utils/Power.sol";

contract BancorFormula is IBancorFormula, Power {
    using SafeMath for uint256;

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    // Auto-generated via 'PrintMaxExpArray.py'
    uint256[128] private maxExpArray;

    /**
     * @dev should be executed after construction (too large for the constructor)
     */
    function init() public {
        initMaxExpArray();
        initLambertArray();
    }

    /**
     * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * Formula:
     * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of reserve tokens to get the target amount for
     *
     * @return target
     */
    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view override returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(
            _reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT,
            "ERR_INVALID_RESERVE_WEIGHT"
        );

        // special case for 0 deposit amount
        if (_amount == 0) return 0;

        // special case if the weight = 100%
        if (_reserveWeight == MAX_WEIGHT)
            return _supply.mul(_amount) / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _amount.add(_reserveBalance);
        (result, precision) = power(
            baseN,
            _reserveBalance,
            _reserveWeight,
            MAX_WEIGHT
        );
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a token supply, reserve balance, weight and a sell amount (in the main token),
     * calculates the target amount for a given conversion (in the reserve token)
     *
     * Formula:
     * return = _reserveBalance * (1 - (1 - _amount / _supply) ^ (1000000 / _reserveWeight))
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of liquid tokens to get the target amount for
     *
     * @return reserve token amount
     */
    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view override returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(
            _reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT,
            "ERR_INVALID_RESERVE_WEIGHT"
        );
        require(_amount <= _supply, "ERR_INVALID_AMOUNT");

        // special case for 0 sell amount
        if (_amount == 0) return 0;

        // special case for selling the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the weight = 100%
        if (_reserveWeight == MAX_WEIGHT)
            return _reserveBalance.mul(_amount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _reserveWeight);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given two reserve balances/weights and a sell amount (in the first reserve token),
     * calculates the target amount for a conversion from the source reserve token to the target reserve token
     *
     * Formula:
     * return = _targetReserveBalance * (1 - (_sourceReserveBalance / (_sourceReserveBalance + _amount)) ^ (_sourceReserveWeight / _targetReserveWeight))
     *
     * @param _sourceReserveBalance    source reserve balance
     * @param _sourceReserveWeight     source reserve weight, represented in ppm (1-1000000)
     * @param _targetReserveBalance    target reserve balance
     * @param _targetReserveWeight     target reserve weight, represented in ppm (1-1000000)
     * @param _amount                  source reserve amount
     *
     * @return target reserve amount
     */
    function crossReserveTargetAmount(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) public view override returns (uint256) {
        // validate input
        require(
            _sourceReserveBalance > 0 && _targetReserveBalance > 0,
            "ERR_INVALID_RESERVE_BALANCE"
        );
        require(
            _sourceReserveWeight > 0 &&
                _sourceReserveWeight <= MAX_WEIGHT &&
                _targetReserveWeight > 0 &&
                _targetReserveWeight <= MAX_WEIGHT,
            "ERR_INVALID_RESERVE_WEIGHT"
        );

        // special case for equal weights
        if (_sourceReserveWeight == _targetReserveWeight)
            return
                _targetReserveBalance.mul(_amount) /
                _sourceReserveBalance.add(_amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = _sourceReserveBalance.add(_amount);
        (result, precision) = power(
            baseN,
            _sourceReserveBalance,
            _sourceReserveWeight,
            _targetReserveWeight
        );
        uint256 temp1 = _targetReserveBalance.mul(result);
        uint256 temp2 = _targetReserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of requested pool tokens,
     * calculates the amount of reserve tokens required for purchasing the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio) - 1)
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          requested amount of pool tokens
     *
     * @return reserve token amount
     */
    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view override returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(
            _reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2,
            "ERR_INVALID_RESERVE_RATIO"
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the reserve ratio = 100%
        if (_reserveRatio == MAX_WEIGHT)
            return (_amount.mul(_reserveBalance) - 1) / _supply + 1;

        uint256 result;
        uint8 precision;
        uint256 baseN = _supply.add(_amount);
        (result, precision) = power(baseN, _supply, MAX_WEIGHT, _reserveRatio);
        uint256 temp = ((_reserveBalance.mul(result) - 1) >> precision) + 1;
        return temp - _reserveBalance;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of reserve tokens to fund with,
     * calculates the amount of pool tokens received for purchasing with the given amount of reserve tokens
     *
     * Formula:
     * return = _supply * ((_amount / _reserveBalance + 1) ^ (_reserveRatio / MAX_WEIGHT) - 1)
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          amount of reserve tokens to fund with
     *
     * @return pool token amount
     */
    function fundSupplyAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view override returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(
            _reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2,
            "ERR_INVALID_RESERVE_RATIO"
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the reserve ratio = 100%
        if (_reserveRatio == MAX_WEIGHT)
            return _amount.mul(_supply) / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _reserveBalance.add(_amount);
        (result, precision) = power(
            baseN,
            _reserveBalance,
            _reserveRatio,
            MAX_WEIGHT
        );
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of pool tokens to liquidate,
     * calculates the amount of reserve tokens received for selling the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio))
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          amount of pool tokens to liquidate
     *
     * @return reserve token amount
     */
    function liquidateReserveAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view override returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(
            _reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2,
            "ERR_INVALID_RESERVE_RATIO"
        );
        require(_amount <= _supply, "ERR_INVALID_AMOUNT");

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case for liquidating the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the reserve ratio = 100%
        if (_reserveRatio == MAX_WEIGHT)
            return _amount.mul(_reserveBalance) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _reserveRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev The arbitrage incentive is to convert to the point where the on-chain price is equal to the off-chain price.
     * We want this operation to also impact the primary reserve balance becoming equal to the primary reserve staked balance.
     * In other words, we want the arbitrager to convert the difference between the reserve balance and the reserve staked balance.
     *
     * Formula input:
     * - let t denote the primary reserve token staked balance
     * - let s denote the primary reserve token balance
     * - let r denote the secondary reserve token balance
     * - let q denote the numerator of the rate between the tokens
     * - let p denote the denominator of the rate between the tokens
     * Where p primary tokens are equal to q secondary tokens
     *
     * Formula output:
     * - compute x = W(t / r * q / p * log(s / t)) / log(s / t)
     * - return x / (1 + x) as the weight of the primary reserve token
     * - return 1 / (1 + x) as the weight of the secondary reserve token
     * Where W is the Lambert W Function
     *
     * If the rate-provider provides the rates for a common unit, for example:
     * - P = 2 ==> 2 primary reserve tokens = 1 ether
     * - Q = 3 ==> 3 secondary reserve tokens = 1 ether
     * Then you can simply use p = P and q = Q
     *
     * If the rate-provider provides the rates for a single unit, for example:
     * - P = 2 ==> 1 primary reserve token = 2 ethers
     * - Q = 3 ==> 1 secondary reserve token = 3 ethers
     * Then you can simply use p = Q and q = P
     *
     * @param _primaryReserveStakedBalance the primary reserve token staked balance
     * @param _primaryReserveBalance       the primary reserve token balance
     * @param _secondaryReserveBalance     the secondary reserve token balance
     * @param _reserveRateNumerator        the numerator of the rate between the tokens
     * @param _reserveRateDenominator      the denominator of the rate between the tokens
     *
     * Note that `numerator / denominator` should represent the amount of secondary tokens equal to one primary token
     *
     * @return the weight of the primary reserve token and the weight of the secondary reserve token, both in ppm (0-1000000)
     */
    function balancedWeights(
        uint256 _primaryReserveStakedBalance,
        uint256 _primaryReserveBalance,
        uint256 _secondaryReserveBalance,
        uint256 _reserveRateNumerator,
        uint256 _reserveRateDenominator
    ) public view override returns (uint32, uint32) {
        if (_primaryReserveStakedBalance == _primaryReserveBalance)
            require(
                _primaryReserveStakedBalance > 0 ||
                    _secondaryReserveBalance > 0,
                "ERR_INVALID_RESERVE_BALANCE"
            );
        else
            require(
                _primaryReserveStakedBalance > 0 &&
                    _primaryReserveBalance > 0 &&
                    _secondaryReserveBalance > 0,
                "ERR_INVALID_RESERVE_BALANCE"
            );
        require(
            _reserveRateNumerator > 0 && _reserveRateDenominator > 0,
            "ERR_INVALID_RESERVE_RATE"
        );

        uint256 tq = _primaryReserveStakedBalance.mul(_reserveRateNumerator);
        uint256 rp = _secondaryReserveBalance.mul(_reserveRateDenominator);

        if (_primaryReserveStakedBalance < _primaryReserveBalance)
            return
                balancedWeightsByStake(
                    _primaryReserveBalance,
                    _primaryReserveStakedBalance,
                    tq,
                    rp,
                    true
                );

        if (_primaryReserveStakedBalance > _primaryReserveBalance)
            return
                balancedWeightsByStake(
                    _primaryReserveStakedBalance,
                    _primaryReserveBalance,
                    tq,
                    rp,
                    false
                );

        return normalizedWeights(tq, rp);
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";

contract TradingStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tradeIds;

    // Trade struct that contains the information about the trade
    struct openTrade {
        address trader;
        bytes32 pair;
        uint openTimestamp;
        uint orderType; //  0 - LIMIT_LONG /  1 - LIMIT_SHORT /  2 - MARKET_LONG /  3 - LIMIT_SHORT
        uint leverageAmount;
        uint collateral;
        uint entryPrice;
        uint takeProfit;
        uint stopLoss;
        uint liquidationPrice;
    }

    struct closedTrade {
        address trader;
        bytes32 pair;
        uint openTimestamp;
        uint closeTimestamp;
        uint orderType; //  0 - LIMIT_LONG /  1 - LIMIT_SHORT /  2 - MARKET_LONG /  3 - MARKET_SHORT
        uint leverageAmount;
        uint collateral;
        uint entryPrice;
        uint exitPrice;
        uint pnl;
    }

    struct pendingLimitOrder {
        address trader;
        bytes32 pair;
        uint initializedTimestamp;
        uint orderType; // 0 LIMIT_LONG / 1 LIMIT_SHORT
        uint leverageAmount;
        uint collateral;
        uint limitPrice;
        uint takeProfit;
        uint stopLoss;
    }

    // Mapping of trades currently open by a user
    mapping(address => openTrade[]) public usersOperTrades;
    // Mapping of users pending limit orders
    mapping(address => pendingLimitOrder[]) public usersPendingLimitOrders;
    // Mapping of trades the user has closed
    mapping(address => mapping(uint => closedTrade)) public usersClosedTrades;

    // cancel a pending limit order
    function cancelPendingLimitOrder(address _trader, uint _index) public {
        delete usersPendingLimitOrders[_trader][_index];
    }

    //return the number of trades a user has open
    function getNumberOfOpenTrades(address _user) public view returns (uint) {
        return usersOperTrades[_user].length;
    }

    //return all the trade information of a specific open trade
    function getOpenTradeDetails(uint _tradeId, address _trader)
        public
        view
        returns (openTrade memory)
    {
        openTrade memory _trade = usersOperTrades[_trader][_tradeId];
        return _trade;
    }

    //return all the trade information of a specific closed trade
    function getClosedTradeDetails(uint _tradeId, address _trader)
        public
        view
        returns (closedTrade memory)
    {
        closedTrade memory _trade = usersClosedTrades[_trader][_tradeId];
        return _trade;
    }

    // a fucntion to return the pair name of a users open trade
    function getPair(uint _tradeId, address _trader)
        public
        view
        returns (bytes32)
    {
        openTrade memory _trade = usersOperTrades[_trader][_tradeId];
        return _trade.pair;
    }

    //delete the trade from the openTrades array and add it to the closedTrades mapping
    function updateTrade(
        uint _tradeId,
        address _trader,
        uint _exitPrice,
        uint _pnl
    ) public {
        openTrade memory _trade = usersOperTrades[_trader][_tradeId];
        closedTrade memory _closedTrade = closedTrade(
            _trade.trader,
            _trade.pair,
            _trade.openTimestamp,
            block.timestamp,
            _trade.orderType,
            _trade.leverageAmount,
            _trade.collateral,
            _trade.entryPrice,
            _exitPrice,
            _pnl
        );
        usersClosedTrades[_trader][tradeIds.current()] = _closedTrade;
        tradeIds.increment();
        delete usersOperTrades[_trader][_tradeId];
    }

    //add trade details to the mapping from a exteranl contract
    function addTradeDetails(
        address _trader,
        bytes32 _pair,
        uint _timestamp,
        uint _orderType,
        uint _leverageAmount,
        uint _collateral,
        uint _entryPrice,
        uint _takeProfit, // 1e8 from front end
        uint _stopLoss, // 1e8 from front end
        uint _liquidationPrice
    ) external returns (uint) {
        usersOperTrades[_trader].push(
            openTrade(
                _trader,
                _pair,
                _timestamp,
                _orderType,
                _leverageAmount,
                _collateral,
                _entryPrice,
                _takeProfit,
                _stopLoss,
                _liquidationPrice
            )
        );

        tradeIds.increment();
        return tradeIds.current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PairStorage.sol";
import "./TradingStorage.sol";
import "./interface/PricefeedInterface.sol";

contract TradingLogic {
    PairStorage immutable pairStorage;
    TradingStorage immutable tradingStorage;

    constructor(PairStorage _pairstorage, TradingStorage _tradingStorage) {
        pairStorage = _pairstorage;
        tradingStorage = _tradingStorage;
    }

    enum OrderType {
        LIMIT_LONG,
        LIMIT_SHORT,
        MARKET_LONG,
        MARKET_SHORT
    }

    uint multiply = 1e8; // 8 decimals
    uint liquidationLimit = 90; // loss of 90% of collateral. The rest will be saved for fees
    uint maxTakeProfit = 900; // 900% of collateral.

    // Get the price of the given pair.
    function getPrice(bytes32 _pair) public view returns (uint) {
        address pair = pairStorage.getPair(_pair);
        PricefeedInterface pricefeed = PricefeedInterface(pair);

        return pricefeed.price();
    }

    // this function will only be used if the trader does not choose
    // to set a take profit for the trade
    function calculateTakeProfit(
        uint _entry,
        uint _leverageAmount,
        uint _orderType
    ) public view returns (uint) {
        OrderType order = OrderType(_orderType);
        uint takeProfitAmount = (_entry * maxTakeProfit) /
            _leverageAmount /
            100;

        uint takeProfit = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? _entry + takeProfitAmount
            : _entry - takeProfitAmount;

        return takeProfit;
    }

    function calculateLiquidationPrice(
        uint _entry,
        uint _leverageAmount,
        uint _collateral,
        uint _orderType
    ) public view returns (uint) {
        OrderType order = OrderType(_orderType);
        uint collateral = _collateral * multiply; // 1e8

        uint liquidationAmount = (_entry *
            ((collateral * liquidationLimit) / 100)) /
            collateral /
            _leverageAmount;

        uint liquidationPrice = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? _entry - liquidationAmount
            : _entry + liquidationAmount;

        return liquidationPrice;
    }

    function calculatePnL(
        uint _entry,
        uint _exit,
        uint _leverageAmount,
        uint _collateral,
        uint _orderType
    ) public view returns (uint) {
        OrderType order = OrderType(_orderType);
        uint collateral = _collateral * multiply; // 1e8
        uint size = (collateral * _leverageAmount) / _entry;

        uint pnl = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? (_exit - _entry) * size
            : (_entry - _exit) * size;

        return pnl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AccessControl.sol";

contract PairStorage {
    constructor(AccessControl _accessControl) {
        accessControl = _accessControl;
    }

    AccessControl immutable accessControl;

    mapping(bytes32 => address) public pairs;

    function getPair(bytes32 pair) public view returns (address) {
        return pairs[pair];
    }

    function addPair(bytes32 pair, address pairAddress) public {
        require(
            accessControl.isAdmin(msg.sender),
            "PairStorage: must have admin role to add a pair"
        );
        pairs[pair] = pairAddress;
    }

    function deletePair(bytes32 pair) public {
        require(
            accessControl.isAdmin(msg.sender),
            "PairStorage: must have admin role to delete a pair"
        );
        delete pairs[pair];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./TradingStorage.sol";
import "./TradingLogic.sol";
import "./AccessControl.sol";

contract MarketTradingControl {
    // contracts
    TradingStorage immutable tradingStorage;
    TradingLogic immutable tradingLogic;
    AccessControl immutable accessControl;

    constructor(
        TradingStorage _tradingStorage,
        TradingLogic _tradingLogic,
        AccessControl _accessControl
    ) {
        tradingStorage = _tradingStorage;
        tradingLogic = _tradingLogic;
        accessControl = _accessControl;
    }

    uint multiply = 1e8; // 8 decimals

    function openMarketOrder(
        bytes32 _pair,
        uint256 _orderType,
        uint _leverageAmount,
        uint _collateral,
        uint _takeProfit, // 1e8 from front end
        uint _stopLoss // 1e8 from front end
    ) public {
        // check if the address is already a user

        uint entry = tradingLogic.getPrice(_pair);

        uint liquidationPrice = tradingLogic.calculateLiquidationPrice(
            entry,
            _leverageAmount,
            _collateral,
            uint(_orderType)
        );

        uint takeProfit = _takeProfit <= 0
            ? tradingLogic.calculateTakeProfit(
                entry,
                _leverageAmount,
                _orderType
            )
            : _takeProfit;

        tradingStorage.addTradeDetails(
            msg.sender,
            _pair,
            block.timestamp,
            uint(_orderType),
            _leverageAmount,
            _collateral,
            entry,
            takeProfit,
            _stopLoss,
            liquidationPrice
        );
    }

    function closeMarketOrder(uint _tradeId, address _trader) public returns (uint) {   // msg.sender
        uint profit;

        uint openPrice = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .entryPrice;

        uint leverage = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .leverageAmount;

        uint collateral = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .collateral * multiply;

        bytes32 pair = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .pair;

        uint closePrice = tradingLogic.getPrice(pair);

        uint order = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .orderType;

        profit = tradingLogic.calculatePnL(
            openPrice,
            closePrice,
            leverage,
            collateral,
            order
        );
        tradingStorage.updateTrade(_tradeId, _trader, closePrice, profit);


        return profit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./curves/BancorFormula.sol";

contract ApedToken is BancorFormula, ERC20 {
    using SafeMath for uint256;

    uint256 public scale = 10**18;
    uint256 public reserveBalance = 10 * scale;
    uint256 public reserveRatio;
    address public reserveTokenAddress;

    /**
     * @dev Fired when LVRJ is exchanged for Dai
     */
    event ContinuousBurn(
        address _address,
        uint256 continuousTokenAmount,
        uint256 reserveTokenAmount
    );
 

    
    /**
     * @dev Fired when Dai us exchanged for LVRJ
     */
    event ContinuousMint(
        address _address,
        uint256 reserveTokenAmount,
        uint256 continuousTokenAmount
    );

    /**
     * @param _reserveRatio(RR) to determine the bonding curve to be used. 50% RR = Linear Bonding Curve, 10% RR = Exponential Bonding Curve
     * @param _reserveTokenAddress Contract address of ERC20 Token to use as reserve/exchange of value e.g DAI
     */
    constructor(uint256 _reserveRatio, address _reserveTokenAddress)
        ERC20("Continous Token", "APED")
    {
        reserveRatio = _reserveRatio;
        reserveTokenAddress = _reserveTokenAddress;
        _mint(msg.sender, 1 * scale);
    }

    /**
     * @dev Mint some LVRJ token by allowing contract to spend an amount of caller reserve tokens
     * @param _amount Number of reserve token approved for this contract to convert to LVRJ tokens
     */
    function mint(uint256 _amount) public payable returns (uint256 _amountMinted) {
            uint token =  _continuousMint(_amount);
            return token;
    }

    /**
     * @dev Burn some LVRJ token and return reserve token based on current curve price
     * @param _amount Number of LVRJ token to convert to reserve tokens
     */
    function burn(uint256 _amount) public returns (uint256) {
        uint256 reserveAmount = _continuousBurn(_amount);
        return reserveAmount;
        
    }

    function calculateContinuousMintReturn(uint256 _amount)
        public
        view
        returns (uint256 mintAmount)
    {
        return
            purchaseTargetAmount(
                totalSupply(),
                reserveBalance,
                uint32(reserveRatio),
                _amount
            );
    }

    function calculateContinuousBurnReturn(uint256 _amount)
        public
        view
        returns (uint256 burnAmount)
    {
        return
            saleTargetAmount(
                totalSupply(),
                reserveBalance,
                uint32(reserveRatio),
                _amount
            );
    }

    function _continuousMint(uint256 _deposit) internal returns (uint256) {
        require(_deposit > 0, "Deposit must be non-zero.");
        uint256 amount = calculateContinuousMintReturn(_deposit * scale);
        _mint(msg.sender, amount);
        reserveBalance = reserveBalance.add(_deposit * scale);
        emit ContinuousMint(msg.sender, _deposit, amount);
        return amount;
    }

    function _continuousBurn(uint256 _amount) internal returns (uint256) {
        require(_amount > 0, "Amount must be non-zero.");
        require(
            balanceOf(msg.sender) >= _amount,
            "Insufficient tokens to burn."
        );

        uint256 reimburseAmount = calculateContinuousBurnReturn(_amount * scale);
        _burn(msg.sender, _amount);
        reserveBalance = reserveBalance.sub(reimburseAmount * scale);
        emit ContinuousBurn(msg.sender, _amount, reimburseAmount);
        return reimburseAmount;
    }

    function calculateBurnAmountRequired(uint _amount) public returns (uint256) {
        require(_amount > 0);
        uint256 amount = fundSupplyAmount(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
        return amount;

    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AccessControl {
    // The constructor sets up the initial roles for the owner
    constructor() {
        _setupRole(OWNER, msg.sender);
    }

    // The available roles
    bytes32 public OWNER;
    bytes32 public ADMIN;
    bytes32 public USER;

    // Mapping of roles to addresses
    mapping(bytes32 => mapping(address => bool)) public roles;

    // Mapping of addresses to roles
    mapping(address => bytes32) public userRoles;

    // Mapping of addresses to whether they are blacklisted
    mapping(address => bool) public blacklist;

    // Modifier to restrict access to only owner account
    modifier onlyOwner() {
        require(
            _hasRole(OWNER, msg.sender),
            "AccessControl: must have owner role"
        );
        _;
    }

    // Modifier to restrict access to only admins
    modifier onlyAdmin() {
        require(
            _hasRole(ADMIN, msg.sender),
            "AccessControl: must have admin role"
        );
        _;
    }

    modifier notBlacklisted() {
        require(
            !isBlacklisted(msg.sender),
            "AccessControl: account is blacklisted"
        );
        _;
    }

    // Set up a role for an account
    function _setupRole(bytes32 role, address account) internal {
        roles[role][account] = true;
        userRoles[account] = role;
    }

    // Remove a role from an account
    function _removeRole(bytes32 role, address account) internal {
        roles[role][account] = false;
        userRoles[account] = bytes32(0);
    }

    // Check if an account has a specific role
    function _hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return roles[role][account];
    }

    // Add a user to the contract
    function addUser(address account) public notBlacklisted {
        _setupRole(USER, account);
    }

    // Remove a user from the contract
    function removeUser(address account) public onlyAdmin {
        blacklist[account] = true;
        _removeRole(USER, account);
    }

    // Adds an admin to the contract
    function addAdmin(address account) public onlyOwner {
        _setupRole(ADMIN, account);
    }

    // Removes an admin from the contract
    function removeAdmin(address account) public onlyOwner {
        _removeRole(ADMIN, account);
    }

    // Check if an account is a user
    function isUser(address account) public view returns (bool) {
        return _hasRole(USER, account);
    }

    // Check if an account is an admin
    function isAdmin(address account) public view returns (bool) {
        return _hasRole(ADMIN, account);
    }

    // check if an account is a owner
    function isOwner(address account) public view returns (bool) {
        return _hasRole(OWNER, account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}