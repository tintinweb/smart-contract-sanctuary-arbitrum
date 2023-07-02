// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract Fuzzies is ERC721Enumerable, Ownable {
    using Address for address payable;
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 150000;

    bool public mintingActive = false;

    string private _currentBaseURI;

    struct MintConfig {
        uint256 quantity;
        uint256 price;
    }

    struct SplitConfig {
        address payable _address;
        uint256 weight;
        uint256 balance;
    }

    mapping (uint => MintConfig) public mintConfigs;
    mapping (uint => SplitConfig) public splitConfigs;
    mapping (address => uint256) public freeMint;
    mapping (address => bool) public whitelist;

    constructor() ERC721("fuzzies!", "FUZZ") {
        _currentBaseURI = "ipfs://bafybeifj2duynsehguy2mbry3lwygcjursibmsgjs7eyfrjgyb4vlkkt3e/";

        mintConfigs[1] = MintConfig({quantity: 1, price: 0.0022 ether});
        mintConfigs[10] = MintConfig({quantity: 10, price: 0.021 ether});
        mintConfigs[100] = MintConfig({quantity: 100, price: 0.21 ether});
        mintConfigs[1000] = MintConfig({quantity: 1000, price: 2.1 ether});
        mintConfigs[10000] = MintConfig({quantity: 10000, price: 21 ether});

        splitConfigs[0] = SplitConfig({_address: payable(0x32Eb42fEEBa8F8D2504FaF25879435dfC65f6327),weight: 584, balance: 0});
        splitConfigs[1] = SplitConfig({_address: payable(0xBa67C8550B2A9941E313C1acC1431c89877Cca2D),weight: 1000, balance: 0});
        splitConfigs[2] = SplitConfig({_address: payable(0x0cD07c72f8Ffd310de0151A7565114B6d5C94482),weight: 459, balance: 0});
        splitConfigs[3] = SplitConfig({_address: payable(0x653384D6B72Bf4BDeD16776363B426B51fF89aEf),weight: 2000, balance: 0});
        splitConfigs[4] = SplitConfig({_address: payable(0x65fdb9E09c9d1ab04888215ac94e132302dBe8B4),weight: 500, balance: 0});
        splitConfigs[5] = SplitConfig({_address: payable(0xD99b34CF3377C841d4bA6d5D627d447Cd862eB8e),weight: 2957, balance: 0});
        splitConfigs[6] = SplitConfig({_address: payable(0x3d67b76CF3dcc881255eb2262E788BE03b2f5B9F),weight: 2500, balance: 0});

        freeMint[0xD25469A1d8789266574F04aC424F72dB4a4f648A] = 30;
        freeMint[0x68b913E2187e1Aa48c64f672F93b8aC318Af01Ff] = 20;
        freeMint[0x0150B0ec3c7b72879FbfdbDD79c18a8368B194E0] = 20;
        freeMint[0x9c6496B92bA94E0DdbD3930382F97b60f7313a28] = 17;
        freeMint[0xE0916c5bd42F843c21A2349f5A9dE3D955cdCEb9] = 17;
        freeMint[0xe43B9D09dBDE7Cabb37Ea29E78024Dc380de4A60] = 17;
        freeMint[0x2531caF72D0296f5e282Bec560C56c6f1c79eBd2] = 17;
        freeMint[0x0e14FCedc3F1469b367aadAabF3AAFEaba97Ced1] = 17;
        freeMint[0x2821014B93ed2313557a6e7c5bEf3488f1e487cC] = 16;
        freeMint[0xD3236F91BC0Df973A9B2F43cC50273Dac8eE4b99] = 16;
        freeMint[0x93B63028Dd964318Ce6C8c0437Be0097F35bc366] = 16;
        freeMint[0x3E672bC03f5C384F371d29E48F0A231acb6EEBd9] = 16;
        freeMint[0x60bF03d02dF1eDa9EAA08AF91A31D95906E8f377] = 16;
        freeMint[0x1e7C86A4A2C65F91FC2A8433a3cAAFCf5D7B64Ff] = 16;
        freeMint[0xD143a8283c6Cf5eE65d9a1df6c4Cb0a19708702C] = 16;
        freeMint[0xd15394Bb4559f912d2da8D590ca0E8f174b3Dbc2] = 16;
        freeMint[0x57681696b6B40e5fE14291c4283465476D887E58] = 16;
        freeMint[0xcDA72070E455bb31C7690a170224Ce43623d0B6f] = 15;
        freeMint[0x31e99699bCCde902afc7C4B6b23bB322b8459d22] = 10;
        freeMint[0x6E388502b891ca05eb52525338172F261C31B7d3] = 9;        
        freeMint[0xa59Fe57dDcb393Dd3Dcaa2bA2766e10D4F38e339] = 9;        
        freeMint[0xe0c87789dF2c506F5EeAAB10BF4C31a92866720B] = 7;        
        freeMint[0x53ADfd2Fd44b5222206091F8475CDE1a53D7E3e0] = 7;        
        freeMint[0xcADe1E68A994C5b1459cCD19150128Ffef09Ea3c] = 7;        
        freeMint[0x05c1ED9Cb27AdAE10c9B7E7B4b74f7521E553F8C] = 6;        
        freeMint[0x9AaE3Bd2b5BA77Ed9e19baDd99C0cB7247D4f159] = 6;        
        freeMint[0x2E21f5d32841cf8C7da805185A041400bF15f21A] = 6;        
        freeMint[0xb6eeD98a7917953093992592D5A606e8d5c82BD5] = 6;        
        freeMint[0xfd79CBF83268bfe7b1Bc7b2788B20Ce3798DAC2e] = 5;        
        freeMint[0xE1471b2a4fa06cE0eb783f34a29b5e897d306Ffd] = 5;        
        freeMint[0x3680EAF1f85BEc9f120bCAAa9ef469fb849E1781] = 5;        
        freeMint[0xeC9e512fE7E90134d8ca7295329Ccb0a57C91ecB] = 4;        
        freeMint[0xCc7357203C0D1C0D64eD7C5605a495C8FBEBAC8c] = 4;        
        freeMint[0x6E513adA916670389097752D05Bf609D1246b4D2] = 4;        
        freeMint[0x731Ed355833856dC1a004354EF06E6157B657264] = 4;        
        freeMint[0x20335C504A4f0D8Db934e9f77a67b55E6AE8e1e1] = 4;        
        freeMint[0xdf6160fE3E5A7D6df67c2BB3D7E100B47eFA243C] = 3;        
        freeMint[0xCF20d98033A4D633252C7DE21f8cbfacC62c394E] = 3;        
        freeMint[0x50353BBB0efc9e84FA6663d5aD5a400d2880937d] = 3;        
        freeMint[0xb63a5C5710F06e111fa14AC82dA2183C5102B504] = 3;        
        freeMint[0x3146a2997E71155c144aE25FCE2d866092Bc91F3] = 3;        
        freeMint[0x16AE9B67Be5d59FCB2FDDEa5b3208943e63A5aF3] = 3;        
        freeMint[0x173216D1fD08e76FD4f25710d2849091cE2fb026] = 3;        
        freeMint[0xee88A8F50F1b77aDC695DfcC34b0C820ec8a3278] = 3;        
        freeMint[0x64A004A4A40661C036d25c8FE182c6AaE0ad4c1D] = 3;        
        freeMint[0xf4E7195b4450360304193b95731E231bB892dADF] = 3;        
        freeMint[0x4af21cb7bFA00A6c30CA1F3C2b45CA5Ce8C669a3] = 3;        
        freeMint[0xb3956cf916D72b56b36577c13F2aCBa868D26c5d] = 3;        
        freeMint[0x6A0129cee67778cd45Df5A35A3802E4fD80b77B9] = 3;        
        freeMint[0x24aB740f0545555e67DA1B317a048eaE217D2fF4] = 3;        
        freeMint[0x96234e93d9fb27fdA6414D89adeB963f126F4704] = 3;        
        freeMint[0x01f85420F032D20C4D24FA4Ef9374C05f935Df67] = 3;        
        freeMint[0x975779102B2A82384f872EE759801DB5204CE331] = 3;        
        freeMint[0x58473E9aC681C4424ca74619281fF71801d002d6] = 3;        
        freeMint[0x5A106F5Cf9fba6aF5DDa6Bde1B8f3bacBd532C37] = 3;        
        freeMint[0x9463eA1dAdF279E174E1075b49B8B7A13d1E7293] = 3;        
        freeMint[0x43cf2F9A8bedaeE11C702daFDb40fad88c48778D] = 3;        
        freeMint[0x7dAa8740FE15F9A0334Ff2d6210eF65BD61ee8Bf] = 3;        
        freeMint[0xaBBDe42239e98FE42e732961F25cf0cfFF68e107] = 2;        
        freeMint[0x7ADE82EA0315954C909c53F4959E06eCff02EE8C] = 2;        
        freeMint[0x83a0Ea0843928Ce98498C493bb02093e7B3Ff71b] = 2;        
        freeMint[0x000000000000000000000000000000000000dEaD] = 2;        
        freeMint[0xA89e1142A9628F706b535373D6C73FA4B98f2047] = 2;        
        freeMint[0xd4cF19f76addb489d079D0f60F41D6E91E7c79E1] = 2;        
        freeMint[0x6aa86d44d562899517e12127732B7D248Fa59E4F] = 2;        
        freeMint[0x772Ad5C5F17c8F1175657B7444553E38152162b9] = 2;        
        freeMint[0x6632d36F72e8A55a817c89392D09529efe0D6978] = 2;        
        freeMint[0xcb8AfA8194245923A5234C2960AA2896C69Bb8Bc] = 2;        
        freeMint[0x47320B27870c9F7549180aA77B0f3BEd292a8b1F] = 2;        
        freeMint[0xCaE8874F70f5b24941FF061e51fB5E1307546F5B] = 2;        
        freeMint[0xF424F275B7D3310EAd34fD43FDFf4be087E6a4Be] = 2;        
        freeMint[0x3546BD99767246C358ff1497f1580C8365b25AC8] = 2;        
        freeMint[0xfF465Cd9d94a39CeB7cCcD5CF0E278E050EFAB21] = 2;        
        freeMint[0x5e15c282EEC06Fa75DA7FC7932c7F53Cc53140cc] = 2;        
        freeMint[0x49ED6145CFf51F4cDCc5AB708a1eFD0f3018d6b3] = 2;        
        freeMint[0x523Ced813d49d94941C0436E77AE4Ffea3545006] = 2;        
        freeMint[0x7A6597Adf4Ba4E405BF5BBe0F5976DC933b089Ae] = 2;        
        freeMint[0x2C08208F59A8299C0b6F0a0dD2696c13588E574b] = 2;        
        freeMint[0x8152bD8f2b02bc881BbbC9E7489fb6DaB03E485B] = 2;        
        freeMint[0x1724AfD62fa47ebe07C48F657e5fa679aaAcCdA8] = 2;        
        freeMint[0xA48C625505F6FfBAfE3D32E8C2974f447e1615f6] = 2;        
        freeMint[0xB2BA7A462a77d7e882225a7E438C366339aED320] = 2;        
        freeMint[0xA98D2867de6b1dFf44Fe4b355DEa098E81d06aEb] = 2;        
        freeMint[0x760AAfc261881f1BB0587Ef76F0dB9c592F7337e] = 2;        
        freeMint[0x8b27C2E167bEb3EFc0Bb3b68fafAAc194a9f0794] = 2;        
        freeMint[0x38C2386AB7627Ac2D3b2E33A972C81E9eF1200eC] = 2;        
        freeMint[0x36a59B5CBFe6F593085Cfac605500A598De8aa13] = 2;        
        freeMint[0xd02Bf535A7164F5935611f48354226Ff5c3278Bf] = 2;        
        freeMint[0xd98Cc53151AD54BBfAD1f2c36aD4C9534026C71f] = 2;        
        freeMint[0x722e9468D7F8C2710b6DbfDF70F01B045aCa1851] = 2;        
        freeMint[0x787cCB43496076b9e726C7ebC07AeEA679C78D0d] = 2;        
        freeMint[0x5CBFFEbDF2F12A8984B9EfF74A85AcAB24730FFF] = 2;        
        freeMint[0x7b994E111Cd89c9391bE815Fa6Fcd6ef2abFD053] = 2;        
        freeMint[0x8261b63b07d1aD92AEB7CDD916bB9a25236CEB65] = 2;        
        freeMint[0x782aDAfbF47a604F146AF4A059908E946eAe539f] = 2;        
        freeMint[0x2632b054cf7eB7e308196F6b13A6acFcBF45b847] = 2;        
        freeMint[0x776C3b715B8f94719371C78da5AAf968180A1ff9] = 2;        
        freeMint[0x6c3675c755c06B236cB10b5ACFa0445FD8AaD455] = 2;        
        freeMint[0x237bf654385602Dc4dCC0f70B2aA024Eed848021] = 2;        
        freeMint[0x33F1D6d439972f118dD22Fb1fEB2969537b2cd79] = 2;        
        freeMint[0xe0482Ce5822D7E3bfBAe5DFA064eF6C9Ff72DeAD] = 2;        
        freeMint[0xF7A11779B0F513d2f77aC4AbA245cE2d867c71d5] = 2;        
        freeMint[0x395FF2285b1C04C4B04BbEEBed4843b8ddda5F3B] = 2;        
        freeMint[0xd0f46a5d48596409264d4eFc1f3B229878fFf743] = 2;        
        freeMint[0x6897c2AD5512E273Efb57Ec6DEB96d49CD83Ee97] = 2;        
        freeMint[0xf27822E9AB6DA97481E6E1533a2314eDC44F41E4] = 2;        
        freeMint[0xFea1F357b453C9CD89b893B07baA6AbfE8536CA2] = 2;        
        freeMint[0x716eb921F3B346d2C5749B5380dC740d359055D7] = 2;        
        freeMint[0xF6d32293C94b61A9d791807F24EB3b7a1165F8B5] = 1;        
        freeMint[0xf79D33fee60208a711932195bA5c2DbD5F751e02] = 1;        
        freeMint[0xb79D661fE3d8B31f8B48BCc34B07E9AbA1EcB2b0] = 1;        
        freeMint[0xaFC634B695daB80e36Aad043DFA803a64183bffd] = 1;        
        freeMint[0xaC61a98fCE9C9Ab2EBb2E2788031258d4719c0C8] = 1;        
        freeMint[0x8e052F66a7354797647532D87FfeDB38467FC354] = 1;        
        freeMint[0xe7BE4B73F17C17b733302107f7153A88DCdd0a31] = 1;        
        freeMint[0x771B1BD0A60cA42eAb4EDBee7740de903bBe15b0] = 1;        
        freeMint[0xd42bd96B117dd6BD63280620EA981BF967A7aD2B] = 1;        
        freeMint[0x8BB07e694B421433c9545C0F3d75d99cc763d74A] = 1;        
        freeMint[0xc53C9755Fb1a26FBCe82c70997920Db503dDe8b0] = 1;        
        freeMint[0x42Dd10D6315EcDfCBfcc8EcEaCCa0BdC9539acf2] = 1;        
        freeMint[0x5bc58B29165372BF5f7CDA9C7b4Bc94a0C8D5A80] = 1;        
        freeMint[0xbd2BF955ee52Acd9F197551748186f4dCD0a8618] = 1;        
        freeMint[0xaCc1ef0a90A8D2000Ef01b0A116b41F2f3cec4B2] = 1;        
        freeMint[0xAF5ffCc81f83595b7639085d3A2DdA4FE9379820] = 1;        
        freeMint[0x4300de18Bbb4750C5601CE6Abd65256FA40f2540] = 1;        
        freeMint[0xa9185E6fd3354EA5a5CB044d9e14f2B9F51c2c6E] = 1;        
        freeMint[0x19d74f3Ab452B027C0ff27612F611477F0A3b1ad] = 1;        
        freeMint[0x55dBAa9ea181CA627D4D664424160C03fE4d5c48] = 1;        
        freeMint[0xe548BC7E002c8dFcD3f9Dc85834ad6378da973d4] = 1;        
        freeMint[0x99c21dC887825A9F6E53ffd6AaF06E78f9c283D1] = 1;        
        freeMint[0x8e50957A3543f03df6Da93A0c88E1F28c5BbaC5E] = 1;        
        freeMint[0xecD9bd6d7d92FeB50DeC093327ff2C75363a79D5] = 1;        
        freeMint[0x0B437b9d2A75Bd885c89F92AD0BCFdBE8C67842a] = 1;        
        freeMint[0x585EE1FA1F0C56b7885707398FD78ba83dC59468] = 1;        
        freeMint[0xBC3Ffa2E6a08C122a56737a14C942fc159Ad4FfD] = 1;        
        freeMint[0x7D76e14487567008cC4C583ADcBa38206eec7C00] = 1;        
        freeMint[0x3d1C4c2b66359F849aE3c63359CE7a767F888c18] = 1;        
        freeMint[0x03969921Ab22b08a78cBcbad85420F1a4b941719] = 1;        
        freeMint[0x2eb577bA34C0d879E9e0493Fd594d89Bf4e3A210] = 1;        
        freeMint[0xb0F18ebFBe9C496A2Ccd6181e48F0EFD5D71c526] = 1;        
        freeMint[0xc3CDC5D1401CbE421A5FFB4a3296810476B35671] = 1;        
        freeMint[0xdcf9a2f38090C12095ffFd9F2fbE01334dec50A0] = 1;        
        freeMint[0xcF63E1C31805254b6fB3Ed7829206c2b2505e3a7] = 1;        
        freeMint[0xAf153E755F59BB62ba8A5b7e5FfDB71c0aC43305] = 1;        
        freeMint[0x1997fDc2775087C8075f93B0Cd2f8B0201e04f6B] = 1;        
        freeMint[0x3925E567b3ED59D1d5444ac902f96Fb949c5fcC2] = 1;        
        freeMint[0x7DEc37c03ea5ca2C47ad2509BE6abAf8C63CDB39] = 1;        
        freeMint[0x3dc3c9aA568A931F5Db9d712503C578e4B430f22] = 1;        
        freeMint[0xF685D63f27Af3E4ABD3a3f51572d166c98384E8d] = 1;        
        freeMint[0xb73b26cf5F3BE4cd7eC58ec7f33B3839ca8b566f] = 1;        
        freeMint[0x0239E81d4cB6Dc7724b531f2A13dc57aa0490311] = 1;        
        freeMint[0x17DAddECA2E11931BaC3EBCcf30B783168C4ec84] = 1;        
        freeMint[0x3ED2079c9ed7228Fe2ab1B64AF6136a8994319e7] = 1;        
        freeMint[0xf2840fb4Cd4f9776F56A1918936C5f17965f6B36] = 1;        
        freeMint[0x7c74F84ab9d211b0aD306fd793c593B744135c49] = 1;        
        freeMint[0xC915D266472685F1ef2F974C5F01B4915F0Df46e] = 1;        
        freeMint[0xBB441f9DE5cB8f0B0a6f35Bc5778df351973Bf7B] = 1;        
        freeMint[0x5275F552373906c3d5B4d0B77fAcae5ab890c774] = 1;        
        freeMint[0xb5322202F151aC36B42Bb5c720038E4ee2A22FD5] = 1;        
        freeMint[0xC0FFEE22F360792a89dB39f159F103dAAFe9C57D] = 1;        
        freeMint[0x9D3517fAC6b51ef714F32C046D5f9bFc7c8Dca0d] = 1;        
        freeMint[0x4d18f8f2aE19f1E166c97793cceeb70680A2b6D2] = 1;        
        freeMint[0xe7fd0F3bdD55eE0fcbB737A2A425259dCA314cb5] = 1;        
        freeMint[0x00eeE67869B81e6331f69831110F9B03b804495E] = 1;        
        freeMint[0x3e5a9821CdEb3E05459985AF81d074F945B32D32] = 1;        
        freeMint[0x3998d2343Ec00A8b1f850B610EE025D712C7921E] = 1;        
        freeMint[0x63AD0FA1E64C27553538Ef5B0F94812Ef6B8D3eD] = 1;        
        freeMint[0x632A7D1c136129d2E0e7628153eED7E227aa43BD] = 1;        
        freeMint[0x261222E46a439Db3a09d8F6a20Acdc4E9fa04D0C] = 1;        
        freeMint[0x5E03049843E8Ec127694bE340ea6f864F315A5Aa] = 1;        
        freeMint[0x51C194Af1dea1c20A4FbaB1677cD5A5F7a768829] = 1;        
        freeMint[0x377bAE577dB8AeeD24Cc3472d6c090381499B69b] = 1;        
        freeMint[0x2AC9e1DE52d1A0a2F2fc03bfb80A9478B0b249C9] = 1;        
        freeMint[0x893b9885Ed48a94Bd76ecB10BD821fC992Ab60A4] = 1;        
        freeMint[0xac4d3E516398b17F8Fa6eED3EEF2F823a939DB16] = 1;        
        freeMint[0x9c391a0CeEb28BD4416d5C3Ff41a12cf0287D75e] = 1;        
        freeMint[0x5daCAf538AB331268292BFD30e92Cceb5b195127] = 1;        
        freeMint[0x08A0636D68AeC2a6F311C7b1A277e1F01ceCDB9B] = 1;        
        freeMint[0x0a2f4Ae163C306E70896AA5F665AdD572B4233B0] = 1;        
        freeMint[0x0d01D1F57A0CDA833b71A4b4821a372f9a26c0A9] = 1;        
        freeMint[0x120F1f5Af551D53990EAdf213de5C2EBC669e080] = 1;        
        freeMint[0x1b9e2eC210d2eA880eA61A2180d55d5C9cFa644c] = 1;        
        freeMint[0x506fA7959774F8D563580806891b15F616C3FFf0] = 1;        
        freeMint[0x661949A7e2E17bBcB4DB0007B009A1333F94D228] = 1;        
        freeMint[0x8FAA1Fc2820f29199724c6a2467C4d578DC84DF9] = 1;        
        freeMint[0x94dF65BcFC14AA9664071e61340710271a68A097] = 1;        
        freeMint[0x982218d451f48C8dB493649f7853ba6901361F11] = 1;        
        freeMint[0x9981E4dE8124eF2bcd078003Caa2a32f275C147A] = 1;        
        freeMint[0x99bDe9082FF67A96C799ecD24D313553Ad3D44a2] = 1;        
        freeMint[0xa7acE9eBCbA507bEf4D976f82ca5B2902Eba7C67] = 1;        
        freeMint[0xA93edc4bB393aFb1F3aE5194b11775c4B3074c59] = 1;        
        freeMint[0xDef2Aa1f87E1645100d9392158b4eDC6c5385fbC] = 1;        
        freeMint[0xEc1bf59b6E5ab05f384fcB8203e7728283AEBeEd] = 1;        
        freeMint[0xeDf00DE7e96923e143A5c4c3e110576B73243754] = 1;        
        freeMint[0x7746883a6E04248169ccE2F663f3CCD512cbf594] = 1;        
        freeMint[0x60f3D979a1ef1392D500d772c86D32fbcF2bB09B] = 1;        
        freeMint[0x7015853F4bE641296f6c92690Ff69FD36704dc2d] = 1;        
        freeMint[0x72AB6547Ee820299D843F38147D017CA817b4a6f] = 1;        
        freeMint[0x6036D6b170416D01A4A1De02A9159ccCEcbAB36E] = 1;        
        freeMint[0xdfaFd868a6dB7BC4aE969681867E86a5B3e6B5C3] = 1;        
        freeMint[0x7ff585E8B619b95bDC37c0cc5f03C9385f5d620c] = 1;        
        freeMint[0xCbfd8A122fc22824156578dA729515FEDa97f2EF] = 1;        
        freeMint[0xCC008786d438Ba1503F96e392E2049F5B2102277] = 1;        
        freeMint[0xadC158F18baF25D7e5E8a4c7Fc11a18110134830] = 1;        
        freeMint[0x5B197894cd1942ac6f7Ab48A1F5CE38D72754b85] = 1;        
        freeMint[0xB63c8F6F2d1bd1ec17a063c422B4282d871704e8] = 1;        
        freeMint[0x642bCBba28560121a5b109b5E7748c819E291F52] = 1;        
        freeMint[0xaE21b4878b6FaFD6915922325d9eda826f14B3fA] = 1;        
        freeMint[0xFb6697e464fD14B98ed37A7a3a3ED3179E7CE0db] = 1;        
        freeMint[0x4D9a0C7ED0d0156b79Bfb3b6ae2E07512591AE9d] = 1;        
        freeMint[0x6515A46069b84FC44b21dE5A17bc740CB73E9676] = 1;        
        freeMint[0x50b14457fC25d32F3c5F330aF97EC8EA1F9EC573] = 1;        
        freeMint[0x3c2B9631Cda622E7375Da0Fa079B27FC49008691] = 1;        
        freeMint[0x71dF0fd7058499E16828463fc030ED9F9c2be2e2] = 1;        
        freeMint[0x55372173689C288552885D897d32f5F706F79aA6] = 1;        
        freeMint[0xbA3fF3564602EbE0f67BF3805300e95754DCf67E] = 1;        
        freeMint[0x24Df86c7C4F8237a942324837151E78Defe936DD] = 1;        
        freeMint[0x9aed2Cc71A4e8cc655a30B1E3C2e7Dfc4b36D7A6] = 1;        
        freeMint[0x317C48dffcE286D83F97bF8F927ACC36e5a6aC58] = 1;        
        freeMint[0x59598CC6A191E2BA7Fb0E3a91CF2A6FA6db6CC4E] = 1;        
        freeMint[0xB6b2d18Aebe30F08539AE4a16Cdc903D9cbe3C57] = 1;        
        freeMint[0xa582Ca249Cf13bAa09a391a8DfD9b99f21Bf0150] = 1;        
        freeMint[0x34c370f0A6234438EA8E83D17E745Fd2C34C857C] = 1;        
        freeMint[0xe16087BeA4471B7a3ea01f1c084b04D19Ada7892] = 1;        
        freeMint[0xC0639c2DE61b3Ee063f9fFB037A6cd034E8c7803] = 1;        
        freeMint[0xF960619F1091A31F824ee3769D10B331C396550c] = 1;        
        freeMint[0x401a7C1A664f716DA64392d3487B39664E63347C] = 1;        
        freeMint[0x1c92fd78A2903DcEA9f316134358c02ab737CBe4] = 1;        
        freeMint[0x75e4d2CD3e6652226808D2750DEbeaF2023E5dE1] = 1;        
        freeMint[0xF237aDa45CB30f9154142d73CbaaD7136954C819] = 1;        
        freeMint[0x28956714F4e111D7Aee9eEd8DC151847ADCeCcaa] = 1;        
        freeMint[0x21E9E5780A5f70B183A9B73a77CfA7FF74E31358] = 1;        
        freeMint[0xBb19e2E744aa2424F4B142704204Ae220e09B514] = 1;        
        freeMint[0xBafaE6Afa1F7B0001860f627354130C859031B76] = 1;        
        freeMint[0xba0f8493cf26ebc23A15DaF89759fe518df7809a] = 1;        
        freeMint[0x8ab83D869f2Bc250b781D26F6584fd5c562FdD9D] = 1;        
        freeMint[0x8364d4b386b8643BaDaD2E633514f431639ebD86] = 1;        
        freeMint[0x6418204239ec9b09Bee377dA4349d5818e689557] = 1;        
        freeMint[0x61CCf1AD4ae3964eeA9cC776552DaAe3397Ab264] = 1;        
        freeMint[0x15F7320adb990020956D29Edb6ba17f3D468001e] = 1;        
        freeMint[0x2812Dc531A3A90c89842BaE03Dd86DDA22689705] = 1;        
        freeMint[0x139a0975eA36cEc4C59447002A875749Ac9c460f] = 1;        
        freeMint[0xE76fF0CC2E48D89e839E6a720546Cfd6a11DCabA] = 1;        
        freeMint[0xe16a3FcADA06cc2B568c8dA7b929a1a135869374] = 1;        
        freeMint[0xC7393721c27C1d3f12C45e783F13FdA4Ee6700b8] = 1;        
        freeMint[0xA043345f524B0A8DE0d417A46aAAe87978284708] = 1;        
        freeMint[0x995E0505603a19EE5C469d2359427BeA68C6e953] = 1;        
        freeMint[0x7ae4D06F38519de6F47f85193C38e1530267974b] = 1;        
        freeMint[0xfccb96245ECE8C0c0ba80992A5719cbA1E2f504f] = 1;        
        freeMint[0x3eC66ad2cD1eD70652b7b1434bc2Ef337AE0874f] = 1;        
        freeMint[0xe2968098A76322279BDb9070B5F7eD7401fEE42E] = 1;        
        freeMint[0x9b6faDedcbE50876eaB12F5109E4C370cb97089E] = 1;        
        freeMint[0xfA5E2931e3A48209B5D0d5D8F857f97f1818A87B] = 1;        
        freeMint[0xe60253102546CE672E550F0b537e3FEe3fE3B6c5] = 1;        
        freeMint[0xB547c85Dd9f3dabbD19E31B805A94F87dE7Ba870] = 1;        
        freeMint[0x7874494CC9C8dFE8B0E3d4303AA4479A93b417BA] = 1;        
        freeMint[0x6D938CbE86b4763691f702577d4046F656aCb3c8] = 1;        
        freeMint[0xdFb18E07d8De064E8d63947aAb312783E8AC831F] = 1;        
        freeMint[0xAEA690A62306b4CA83F7748a904eb4Eb938abFd4] = 1;        
        freeMint[0x606d2C436A07be40C276a6176bb1376C34e49Ee9] = 1;        
        freeMint[0x36794F190186df6bd91Db8296d4CaC5dCBC57758] = 1;        
        freeMint[0x1558d9b3B5b37e9249AB6c6ceF343eF53a3D67e5] = 1;        
        freeMint[0xFb67f01890F3AC74502192B7f5c79878773C77Ce] = 1;        
        freeMint[0xfA3A28bc7BEedf3E196B0EfB8804313c285B33dC] = 1;                
        freeMint[0xEec7689e935A0d8c440f9B1d403f0b6305935788] = 1;        
        freeMint[0xBEb59BC20AEA53b45bC778Da701ab86e8A62eA79] = 1;        
        freeMint[0xb55d612F7fF827e5805e978c049108C2717a7e33] = 1;        
        freeMint[0x41a847f8e545C3111403240C76890134bbCC166E] = 1;        
        freeMint[0x3bBd42a00D0B6A51DAC17B098034F7E728647F1f] = 1;        
        freeMint[0xEB95ff72EAb9e8D8fdb545FE15587AcCF410b42E] = 1;        
        freeMint[0x45259cE57bf58447CBA7EbEF56C97412B1f9e2B8] = 1;        
        freeMint[0x4262cD025aD16fA24205FaF35327316ef35a1D1C] = 1;        
        freeMint[0x4258911eBf6Db3f93f7DCc6A12F53aaB03dd47da] = 1;        
        freeMint[0x405CbD23b0f722f59dD847EA45737244b04B8e2b] = 1;        
        freeMint[0x3c3cAb03C83E48e2E773ef5FC86F52aD2B15a5b0] = 1;        
        freeMint[0x36cbbB27Db5c8AE4Ea9AB2433d4494b3154bE2CB] = 1;        
        freeMint[0x3612b2e93b49F6c797066cA8c38b7f522b32c7cb] = 1;        
        freeMint[0x30Ba084d347d88Cf2e4f70dB99403C8F672e66fd] = 1;        
        freeMint[0x25d438f198ec6710eb7DAf5c6EBcF173e36F3567] = 1;        
        freeMint[0x233E4CE072d470e1Db46f0c19b855DCC4698e735] = 1;        
        freeMint[0x0D07534E7062e6B8ae0ceFB553B45a12C5d84f0a] = 1;        
        freeMint[0x06a5e5A9A302ef974a0E2aF9328EAeA40C9599b8] = 1;        
        freeMint[0xd1e8A92f44Bdc83BC620c56A7913fd97De5abE10] = 1;        
        freeMint[0xdEd1ac452E8c9fB036Bed368dd414b75da177B48] = 1;        
        freeMint[0xF738a2641eCDB9C2506Bc0Bc8E4E973bB7B3cADC] = 1;        
        freeMint[0x11C45b1005009Ad48B229d895B3EC71f3360e562] = 1;        
        freeMint[0x429f42fB5247e3a34D88D978b7491d4b2BEe6105] = 1;        
        freeMint[0x53Db06881e8f040190a3778A21bc86a0122793D9] = 1;        
        freeMint[0xCE1da4d1B55a4dab241e78C68eaD83730670c4CC] = 1;        
        freeMint[0x612f34973b6be6Cc1243d76b7770541f2c4dF793] = 1;        
        freeMint[0xC6f8bfef9cdB009Fa1577b9d80F79661D674fd25] = 1;        
        freeMint[0xc34FaB987f03Ee188D4C8E0e7132D78E20a3EdAe] = 1;        
        freeMint[0xC2A3d18B710821E0e6dFC8002f8EAABC137BA4dA] = 1;        
        freeMint[0xBA9BB8c76a4D0a62f10A1ca28B0B348d57712e7d] = 1;        
        freeMint[0xBa68be12C7C46c5C9243a6747514A721A947Df10] = 1;        
        freeMint[0xb7a2b83E90f4b8ad8C733CB819b30Cdcfbb6F736] = 1;        
        freeMint[0xAd170E62645cA0C2E842b62F8A2dd68f001709aB] = 1;        
        freeMint[0xABE67ca4eEfbEFd5217e35222896b9fE8C5DAD43] = 1;        
        freeMint[0xaBb94DBdD360CC0eE92B59420A49019e760e32b3] = 1;        
        freeMint[0xa9CcC49a14B707B9Ec062aD83983c41fFC2A2e4e] = 1;        
        freeMint[0xa2b497e290745e6Fb16cb64041437C8569ead6e3] = 1;        
        freeMint[0x973F5A0fE2f82f06f96Bb663D6e3AA00F055F0b1] = 1;        
        freeMint[0x90c19feA1eF7BEBA9274217431F148094795B074] = 1;        
        freeMint[0x9079a0a7e0eBEe7650C8c9Da2b6946e5a5B07C19] = 1;        
        freeMint[0x6381A0e9B2a472bDEc08Bf4524E3C5Ef576925C0] = 1;        
        freeMint[0x0396Dd6aCc42cE2f0733e2E6FeD7cD157ec930C1] = 1;        
        freeMint[0x0B4e8E4D3B3d72D1fa798B74F09CAE5C71C16c83] = 1;        
        freeMint[0x0B742783bFAc8D4b6d332E5D1b63F433FCD8c0A0] = 1;        
        freeMint[0x42305E88559E78dA281dd1AD26831C1a9f1f5d5c] = 1;        
        freeMint[0x4ecCA26ddCeA22f744D3913E440e712154336669] = 1;        
        freeMint[0x4f5BAB2c13086B01abAFb02857934C332A42972c] = 1;        
        freeMint[0x0453666Dd9E1a17F8B38cEA6d2B9189546263572] = 1;        
        freeMint[0xC5d0480FAd0d9e4b0d5752BD0569414F7E47b972] = 1;        
        freeMint[0xAE49C1ad3cf1654C1B22a6Ee38dD5Bc4ae08fEF7] = 1;        
        freeMint[0xacE38b774A5E2c098574D7eE0FC9406d4FE7f768] = 1;        
        freeMint[0xA83444576F86C8B59A542eC2F286a19aB12c2666] = 1;        
        freeMint[0x9A38C3dC59E58Bd5E83BeEa6d018Cd4744981C6a] = 1;        
        freeMint[0x93deBF2290FDf6Ce6F4dfE722Bb01A628233Be55] = 1;        
        freeMint[0x7d703Bf8Bc9B4710408ED8E392122C66D501CD75] = 1;        
        freeMint[0x73d97C30603b73CF4cCdE4934C6027A9599D861D] = 1;        
        freeMint[0x735eD02655Bca15EC46491C0dE4946591135459b] = 1;        
        freeMint[0x31c06A69DbDe6a7c5e5924C57002c9C550bBC367] = 1;        
        freeMint[0xE7bd51Dc30d4bDc9FDdD42eA7c0a283590C9D416] = 1;        
        freeMint[0xE7b38F2AD13e40e72F7Ef901da03ac72E50F5329] = 1;        
        freeMint[0xd83534E5d0d1e15382152abacc7A9Ee28BDa42f8] = 1;        
        freeMint[0x47aCEA791D5567be57f8F67d7930a360A4F90C43] = 1;        
        freeMint[0xD240B2b164303024b84c217285cdD1F838735284] = 1;        
        freeMint[0x6351246F13c4860dd3cE5Ad2439D784B3e6AD173] = 1;        
        freeMint[0x1Df4992D3947EB4c651a01e9c749a8EFc79A2190] = 1;        
        freeMint[0x0A2ef7C6098e564361137407Bf6e9300E3DeD7C2] = 1;        
        freeMint[0x0943592CF6C2b4d7169f87bB721bE6a6E2B23832] = 1;        
        freeMint[0xbb1eC73938b9Df4baaB4F5c43AF96385A862811E] = 1;        
        freeMint[0x9649e370EE6fAcC62E1849eAB6f4BE7A2b5f4A13] = 1;        
        freeMint[0x90Bb8f4cbeEe43a6c1F6BFb492CF53a35DE4352F] = 1;        
        freeMint[0x7D84C78B826F571381B95204e69469836eE759f2] = 1;        
        freeMint[0x0e92e56b69a53C6bbbd426408A09c0b47B5DDa27] = 1;        
        freeMint[0x0c9e596F2980a1C7e1159C1d6d0332Bc0AC5cE21] = 1;        
        freeMint[0x03cF94a41888F58372B987AC4052B770f19b7d51] = 1;        
        freeMint[0xC5c84ABdb06e9B652E054835db25B0c8f24c534b] = 1;        
        freeMint[0xB78b708B810DB3D9dcDcd74287EB825446a298cA] = 1;        
        freeMint[0xB738d7Efc9e75259e3E41Ec2cDc8Ca83253Bf308] = 1;        
        freeMint[0x8Bff6c42fa5507926C6fBaa12Cb82BC090F98189] = 1;        
        freeMint[0xb2818Bf247F387DBa67ee2E40ebB284B52b59B22] = 1;        
        freeMint[0xe5932aeDF1e7B5E3c79eF7271E41A0B0B0f84aB9] = 1;        
        freeMint[0xcC40bfAbC12Ba34d86a9292D95647B658fb3b333] = 1;        
        freeMint[0x1507A7c4d3b8D9AAd7D10cDce52a0CaF7905505d] = 1;        
        freeMint[0x6088Fa0dd64D6E67aCEA807209161310e5956683] = 1;        
        freeMint[0x5d9E737911a7bA6B91f7370728C0a099D1D9e615] = 1;        
        freeMint[0x57Aa377b489Bd2efd1B84182298D3CE5E2075C49] = 1;        
        freeMint[0x55eF1817Bca4444Ad3c94266923b978AE29FeB5c] = 1;        
        freeMint[0x55337cD8CEF0badB8852397e78A78CD7a9ABaDF7] = 1;        
        freeMint[0x515544B39eb1A6e03F13969D696dA0F014cb175F] = 1;        
        freeMint[0x4d1AeA7b20F04b1F9f18222a5BDA1d380Be567Cd] = 1;        
        freeMint[0x4CBACFF596c12924aF2E0300638a40fe329AA49F] = 1;        
        freeMint[0x49f715daB03EF0872F0f6Dae938cF310c447ad52] = 1;        
        freeMint[0x43368deDa023351e4843e9C757EEF90FccC2AFf6] = 1;        
        freeMint[0x3ceB5e40E76eD5C483845C58542ed4e5d13cEAAB] = 1;        
        freeMint[0x3929EFF8e0FEb3166992942d8b9030D95646C3ce] = 1;        
        freeMint[0x34934daf75B681796354086d3055B821FB3fa51d] = 1;        
        freeMint[0x343c14FB65fA22803c42E7757edb51e8a8DBB91C] = 1;        
        freeMint[0x2638fF4BDbBba6930A014B84E848Ad3f70253bd8] = 1;        
        freeMint[0x1Fe2514A72D88f390F0510fCcBB3d55E20EE98f7] = 1;        
        freeMint[0x5F5ae93Ba80Af9C972921b6fD343103aecd04a35] = 1;        
        freeMint[0x6c167Ae3f9247CCFBe9b9Bf3C1b014612ca680A5] = 1;        
        freeMint[0xcc03C4cA24abAB228b79fc6f98834a6e5638336a] = 1;        
        freeMint[0x76166a396656623F9D39CCE6a910464847B946Fe] = 1;        
        freeMint[0xc99A05cA80A214e5f494EFb67B698b88D2D1E393] = 1;        
        freeMint[0xC30f95ba13b57939622e29b083f75DFB123B736c] = 1;        
        freeMint[0xBeFB79854E5073077b6204357a2B48D2DFDE8C43] = 1;        
        freeMint[0xBcc94f4c922736925e0E9C15391657888e85F435] = 1;        
        freeMint[0xBC24EBab7b97375Bb039d51aDd8beD21dAD2B891] = 1;        
        freeMint[0xAFD8bb32837E418B557BF254529940965E6fD9b0] = 1;        
        freeMint[0xA9719b18FF620a2E4D95c2B64674C5524cc948F4] = 1;        
        freeMint[0xA8d2f83ddccAEeeECaAd63Fec7A94e74504351B2] = 1;        
        freeMint[0xA892631eAcaF19dB0B229D08B3a02E5E53Ff37C1] = 1;        
        freeMint[0x9B3632Eaf21a04daEeb3602a66B19248F75214Ba] = 1;        
        freeMint[0x92f708cF04A083Df54f77124abb8ec22692e3bb5] = 1;        
        freeMint[0x90FA47e64c359e2476F548a95ba1d9d7956185e2] = 1;        
        freeMint[0x8d809b30Ce1d511c674784c4bcFCd5D28F957F5C] = 1;        
        freeMint[0x796aA87fda403F3eC325F1e3c410282526DAF8fB] = 1;        
        freeMint[0x7778B343eF92c338a2fbaC055B0e03BCaB73dE08] = 1;        
        freeMint[0x4A321d9AD33d7a48d6900229372e878F0eD74DC7] = 1;
        freeMint[0x8F53b68B494c54C82511161F0F2811820e931B72] = 1;
        freeMint[0x954CF85C6FE27B8747EC5D5E8aFeAdb7cC2d4Ed0] = 1;
        freeMint[0xDD660D84f32a9b52EBBB71506c097c371eE9f1f0] = 1;

        whitelist[0x582b2aFD5Ff1f5342BB7d63439a8E2Fd0bfe0Fe2] = true;
        whitelist[0x69940FA993541F4AEcfC6e1b3E1dB48652FD78Aa] = true;
        whitelist[0xca06fBDE588a97C4E16A844494D387087337147F] = true;
        whitelist[0x0B95f218d9032eBcb9ea928c7621e2EC7d19E390] = true;
        whitelist[0xaC8EbEb5F3a0187d49e85d304547609387512EB2] = true;
        whitelist[0x68d4DE88242c726059d85bD4E095C4a77b6B7FEc] = true;
        whitelist[0xCb213584754b36Ccd2b9941458a280AF93955Afa] = true;
        whitelist[0x1e8bd2740f37b8080FD9FF109F887507758D737f] = true;
        whitelist[0x4d3eA84141aAa8f0f319435A3c79027afc1565Bd] = true;
        whitelist[0x325871d0EF3F27c4f837c4714aE5C2ba5B543425] = true;
        whitelist[0xe9b95AED33b899870Db3dD936788eb942570fd09] = true;
        whitelist[0x7e02284c447cAB8E3c7416AD44Defb61217f3FDC] = true;
        whitelist[0x2aFC28b45FceB281BCbe95E27618AF7538945631] = true;
        whitelist[0x9578614bd52Ff257dF35B7303Aa9BeE0266Bc5Be] = true;
        whitelist[0xFD5Cb30b343436D7336c504b0FCecCD619cC700d] = true;
        whitelist[0x32E3E093999993d6B4aAc253B9b9840C5DE95870] = true;
        whitelist[0xD63b1828B35D1F4075Aa7F8a32D69c87795AA8D1] = true;
        whitelist[0xdDC97A6946cbd45738d9a1B1F58537415bE05F6B] = true;
        whitelist[0x3abb9f1455fD9Dd6013c6aBe3A562B85a7eC871E] = true;
        whitelist[0x59C7602dFf791B5eC0348Cc0F6bDB73066De34E7] = true;
        whitelist[0xD6A70509e5Fc33bE6427BAD9915B272Ef6A198bD] = true;
        whitelist[0x279C8b74ba7c6031dBd3D9D2444A2374fc267f70] = true;
        whitelist[0xd6cB59AF1cF93720f277957d98A6483A228820bd] = true;
        whitelist[0x12Bb206124930a2533F9147f2f134a5372EA5b91] = true;
        whitelist[0x01C8Cc82C4BC402CBA646C466a4F821473F6DB26] = true;
        whitelist[0x8aB4e6A5DB48a154B8B718c416113dc73193142e] = true;
        whitelist[0x8E31d63313b75112F3F33912696a1B264951Eadd] = true;
        whitelist[0x25b75A6E15aC0407D5FDeF3c13287F5bb03EF36c] = true;
        whitelist[0xf8a021755E0bfD90B3ccf12656c1802861696eBF] = true;
        whitelist[0x970C603Bd74c30c9991a2F72B41ACAE5a4489E2C] = true;
        whitelist[0x2f6C73FD2605c15D0580357AeDbeF131F4a8A8a1] = true;
        whitelist[0x3E45bF64C54265Cc4bfDf26d88C77bd9795973B5] = true;
        whitelist[0x0367e1A04BC969B75b08e447bBfbb6D65436A82D] = true;
        whitelist[0xD0476bE41995B8dE49ab5Df7Bb3e930B42261Ad4] = true;
        whitelist[0x61956c32bE15cf7255eC6441eb1786e1700DC190] = true;
        whitelist[0xb8695C162918B1199C3ac0C99795432c0041418D] = true;
        whitelist[0xe391cC678d9Cc917fe5Faaa2FE2F41257776A56a] = true;
        whitelist[0x83d7B39E6BAbEA3F4fADD4eb072491b72EBe17Cd] = true;
        whitelist[0x8372653a21BcB5049E2A8085C4CE6152c19D7038] = true;
        whitelist[0x3Cd05187EF487c24DF368fb820147Ca9b14112Bb] = true;
        whitelist[0x6387043a972795e4804AE1737B7596B2399eFdfa] = true;
        whitelist[0xCA9eD54d46844fF4971c2ecD64f8bfF963C9F1db] = true;
        whitelist[0xec4Fad3aF39fe66031AbcFaF99F6Eb1563D0Ca4E] = true;
        whitelist[0x9f2859cf7eA3678374Aee0429B78522F993342E4] = true;
        whitelist[0xc4Cd42F75A92dedaD68e4C5fcdb86216354613c2] = true;
        whitelist[0x7cEa181e2FdF66D63ADD2030F81464E95c5bA67A] = true;
        whitelist[0x3773f1021d690Bcd8D218960ef7853629b25bdad] = true;
        whitelist[0x17C3be17E2E0db62e47f7d494426bEB7073De6B6] = true;
        whitelist[0xEC225a1Fd31603790f5125Ab5621E80D8047E901] = true;
        whitelist[0x6c167Ae3f9247CCFBe9b9Bf3C1b014612ca680A5] = true;
        whitelist[0xb369A1Cf34817C984e8c474B76a0cc845f18F281] = true;
        whitelist[0x0Edfa76A60D989B8911C8E9E949a9854B0607fE5] = true;
        whitelist[0x0000000dF24D1de30E8B5B9bE481ecfc35C834f0] = true;
        whitelist[0x3Ab62BaFACbb8030CCa852924b41aD3aF7919a41] = true;
        whitelist[0x2cd6eFF125840272af0182197854984d6bEd5f93] = true;
        whitelist[0xA0CAC4f329a3F53FD0AF8C4A26aE61085eD46c81] = true;
        whitelist[0xbCa667D21b17363b5fe94988Af0f3F494375d8d9] = true;
        whitelist[0x4f5483aBbc185cc9e371c99df63b6716260b1244] = true;
        whitelist[0x7964c359995F0fc2095c8539db57FdD0A7180De0] = true;
        whitelist[0x475606d141047A655aEfFd2055448E4B7Ac2Cc58] = true;
        whitelist[0xAd148bcC74E9C6f2914e85516f9A1A3806367FC4] = true;
        whitelist[0x075311cf6189c2Db57bb10027d710ab6C42B7874] = true;
        whitelist[0x57F3F54143699194c40Fe462675515082937B208] = true;
        whitelist[0x656211f6eC16B75c1cd6F423c0134ad141f0C5d6] = true;
        whitelist[0xA7A884C7EbEC1c22A464d4197136c1FD1aF044aF] = true;
        whitelist[0x038D1BCDF13bCfCf82604c0893Ab598c243b21F8] = true;
        whitelist[0x88A0429f1eaF787EC9C808cF6A40f0f2bB97c4Ba] = true;
        whitelist[0xCF24D00696931A5cCc5F8d3F931FEd2B100df8A2] = true;
        whitelist[0xa4C45893F095F9DA82AcD9B52Fa16a7Eb947B02c] = true;
        whitelist[0x838Eb6724E3Cd7C5FDdd29C9E303a3c503483312] = true;
        whitelist[0xcF8d3063e7074B38f4548A7e2798CE2D498A8Ee2] = true;
        whitelist[0x8f1B03B58c22B8798a35f2A10e5E18769c672C1d] = true;
        whitelist[0x9F041fBbc6fd007115dae9BD1cE6001B26747797] = true;
        whitelist[0x6Dcd18d1AC359f70789d59A50cF82EE46371AFD2] = true;
        whitelist[0xfd7DcB59fd197C461591856Ff2D11736561E1369] = true;
        whitelist[0xec5Be8F2b40d298B4F24e2d9cb7d7104f62111AE] = true;
        whitelist[0x0cD07E6B92ae3FE61fA57941d3F461057450c160] = true;
        whitelist[0x02a4e2396cfEBd5eFc0Df83F99c3f2129c32F3B8] = true;
        whitelist[0x84D1a93ca0AcAaa8526626F3a20b49485c1C28B2] = true;
        whitelist[0x32BFDEA7e03AE2b2fD9D593aE35533dBE839B59B] = true;
        whitelist[0x5eD47a3A19F6b34cB0889293bAFEBaF0ACd16021] = true;
        whitelist[0x5576b376039C023Cdf0A32C35348ba5340FA2c9e] = true;
        whitelist[0x55cb99106aDB9E0E69A1877200CAba13223Eb96b] = true;
        whitelist[0x06c4Ad68Cac06A05Ff427b1238D6514471AFed72] = true;
        whitelist[0xceB4e09827b1cE8EE4A3b1bc1F4E73bcf2d7AE41] = true;
        whitelist[0x1724AfD62fa47ebe07C48F657e5fa679aaAcCdA8] = true;
        whitelist[0xd34804C749df87c17c44b1ee31ED7f25C9476B4a] = true;
        whitelist[0x3d8f02628508E0576dF63F1b7F4E9E367cc67400] = true;
        whitelist[0x917F9607Ab8d504286c885562d237a340cbc6879] = true;
        whitelist[0x499Ba182e2F22C59080DdD93197aAb2a5aEa5154] = true;
        whitelist[0x8fF78a229B50A65f90572BE621893186f3835804] = true;

    }

    function mint(uint configIndex) public payable {
        require(mintingActive, "Minting is not active");
        require(totalSupply() + mintConfigs[configIndex].quantity <= MAX_SUPPLY, "Exceeds max supply");

        uint256 price = mintConfigs[configIndex].price;
        if (whitelist[msg.sender]) {
            price = price * 85 / 100; // apply a 15% discount if on whitelist
            whitelist[msg.sender] = false; // remove from whitelist
        }
        
        require(msg.value >= price, "Incorrect Ether value sent");

        uint256 supply = totalSupply();

        for (uint256 i = 0; i < mintConfigs[configIndex].quantity; i++) {
            _mint(msg.sender, supply + i + 1);
        }

        splitFunds();
    }

    function mintFree() public {
        uint256 mintsAvailable = freeMint[msg.sender];
        require(mintsAvailable > 0, "No free mints available");
        
        uint256 supply = totalSupply();
        uint256 mintsPossible = MAX_SUPPLY > supply ? MAX_SUPPLY - supply : 0;
        
        uint256 mintsToMake = mintsAvailable < mintsPossible ? mintsAvailable : mintsPossible;
        require(mintsToMake > 0, "No mints possible at the moment");
        
        for (uint256 i = 0; i < mintsToMake; i++) {
            _mint(msg.sender, supply + i + 1);
        }
    
        freeMint[msg.sender] -= mintsToMake;
    }


    // Override the baseURI function to return the modifiable _baseURI
    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    // Add a function to allow the owner to change the baseURI
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _currentBaseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
            : '';
    }

    function splitFunds() private {
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < 7; i++) {
            totalWeight = totalWeight.add(splitConfigs[i].weight);
        }

        for (uint256 i = 0; i < 7; i++) {
            uint256 share = msg.value.mul(splitConfigs[i].weight).div(totalWeight);
            splitConfigs[i].balance = splitConfigs[i].balance.add(share);
        }
    }

    function withdraw(uint configIndex) public {
        require(msg.sender == splitConfigs[configIndex]._address, "Only the intended recipient can withdraw");

        uint256 amount = splitConfigs[configIndex].balance;
        require(amount > 0, "Nothing to withdraw");

        splitConfigs[configIndex].balance = 0;
        splitConfigs[configIndex]._address.sendValue(amount);
    }

    function setMintingActive(bool _mintingActive) public onlyOwner {
        mintingActive = _mintingActive;
    }

    function setFreeMints(address _address, uint256 _quantity) public onlyOwner {
        freeMint[_address] = _quantity;
    }

    function setWhitelists(address _address, bool _value) public onlyOwner {
        whitelist[_address] = _value;
    }
}