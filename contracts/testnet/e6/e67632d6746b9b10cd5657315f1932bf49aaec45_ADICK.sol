/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: Unlicensed
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


/*
J~~~JBBBBB#B####P?7~~YBY!~~?7~::^^::....::.............::::::!:...::.::.7:^!7Y5PY7!7??!!7!~!Y5JJ7?!?
#J~~!P#BBBBB##BY~!~!557~~JY!:::^^:..............::........::~^....::.^::? :7?PPGB7.:!5?J?55J5B5Y?J7!
&B?~~J#BBBBGB#5~~^7J7!~?Y!::::^^................:........:.^^.....::.^:^7 .!7PGGBY ..77JY?5P5GGYJJ57
G&B7~7B#BBGG##?^~7~~7!?7:.:::^:...........................:~ ......:.^.!7 .~75GBGY...^7~P??JY5BPYJP5
5B&B7!P#BBPB#B!~~~!!~!^.::.:::::.........................:~........::^.7~..^7JBBBP:.::!~JP??J5GBG?~J
PPG&P7P#BGG#&G~~^^^~!^:::.::...........................:.~:.........:^.?^..:7?GGBB?..:~?!GY!?JP##5:~
PP5G#YGBBBB#&5^::^^^^^::..........:.....................^^ .........:^.?^..:~?5GGBG!..:!7?B!7?Y#&B^:
P55YGBB#BBB#&?::::^^:................:.................^~............^.?^...:7JGPP#G: .:7!P5~??G&&7:
G5YY5PB##B#&5~^^::^:.........::............... ......::!............:~:7:....~?PGP##5. .:!!B7!7J#&P:
BPYYYY5#####~^^::::::......:::.....:......... ......::~: ............^:7:....:7YGGBBB7 ..^!JG~77G&#~
BGYYYYYG##&5:~~^^^^~~!7!~^^:............... .......::^~ .............^^!^ ....^?GBB#BG^...~!PY!!?#&J
5GYJJ55G&#@?:~~~7?YYY55YYJ77^::::......... ........::!...............^^!^   ...~JBB##GY:..:~!GY~!5&B
?YJJ555GB&&!:!?JYYYJJY555YYJ?77!~~^::::...:..:....::~^ ......... ....:^~7   ...:!YBG##B?:..:~7P7~?##
?JJJ5P5PB&P:~7???77!77???JYY55P5YJJJ?7!~~~!!~^:..:::!.......... ......^^J:  ...:^75GB#&#^...:~?G!!5#
J5YY5YJ77G7:~?77!!!!77??JYPPP55YY55YYYYJJ??7!~:..::~:..................:!!  ...::^7PPB&@Y.....~JG7?#
PG5?7!~!5P!^!?7777777?JJJJ????????77!!!~~~^^~~^:..:^..........:^^^^::..:~?:......:^7GG#&&~ ....^JP?G
B#GY7~!5PY!^!?77!!!7?JJ??7777??7777!!!~^^:^^^~^^:.......:....:~?J777~::~!?7::::^:::^?BB#&B... ..^?5P
5#&#J!55?7!~!?!!7?JYJ?J7~!!~~~!77?77!!^^^^^^^^^^:...........:~77!~777!7JYY5J?7777!!~~JBB#&Y^^:...^?5
?YGY7?!777!~~7?7J5YJJYJ5JJ5J?7!~~~^!77!^~~~~^^^^:...........:~~^^^^^~~~!7JYY55YJYYYJJ7JYYPPYJ7!~^:^!
7!7J7~J&B57^^^!?JG#BBG55?!G#BPBBB5!^:!?!~~~~^^^^:...........::^^^~^^^^~~~!777JYYJ?J????77??YYYYYJ7~^
J5PY7~Y#@@?^^^^^~?5PY?7~::5#GP&BB##Y!~~77!~~^^^::..........::^^^^^^~~~~~~!!77!77?777?77!!~~!7777??7~
#BPY~^^!5&J^~^^^^!YP5J7!~^^YB&&&#G?:~7!^!7!!~^^:..........::::^^^~!!~~~!!7??????7777??7!!~~^^~~~~~^:
5P57~~~!7PY!~~~~~~7J55YJ777!!?J?7~~!!?YJ^~!!~^^:...........::::^~!!!!!!77777!!7!77777777!~~~^^^^^^^^
G5?!777?YG5?7!!77!!!7??JJJ??7777?7???7?Y~:^^~^:::............::~~!!!~~~!7!!!77J??J?!!~^~!~~~~^^^:^^^
GPJ???JYP#P?7!77?J?7!!!!!!!!!7777???7!!~^:^^^^^::..........:::^~~~~^^!?YYYJP##G###&##P5Y!~~~~!!::^^^
PP5YY5YJJ55??77777??77777???JJ??????7!~^^^^^~~^::........::::^^~^:.75PY7^^:~B##&GB##B~?PBG5J??7!~~^:
BGPY?JJJ?????77??J??JYJYJJJJJJJJJ???77!!~~!!!~~^:.......::::^^^^::^???JJ7~^:!5#&BBGY: .^?G#&BGY!^^:.
P5PP5JJJJJJJJ?J?JJYY55YYY??JJJJJ??777777!!777!!~^:::::::^^^~~~~^::^~77????7777777~^:^~7?J555J!^:::::
BPPBG5YJJ?JJYJ??????JJJJJJJJYJJYYYJ?77!!77777?7!!~~~~^~~~!!!!77!!!7??JJJJ?77!77??7?JYYYYJ?!^...:::::
BB5YYY5YJJ???J7??77777777777777??7??YJ!~~~!!!7!7!~~~!!!!!7??????????JJJJYYYJ?!!!!!7777!!~^::::::^^::
5PG55Y555YJJYG7!7777777777!!!!!!!!!7?JY?!!!77!!!^....:^^!J7~^~!???YYYYY5555JYJ????77!!!!~^::::^^^!!J
JJY555Y55YY5B&G!~!!!!7!!!!!!!!!~~~~!?J5JJ??JJJ77~:...:~7Y7::7J777!7???JYY55Y5JJYYY7JJ??77!!~~?J?JPP?
P??YYYYY5YYG##&G7~~~~!!!~~~~~~^^^~!!7?YPYY5J????7~^^~??Y?^!Y?7!!!!!!!!7???????J???7JJJYYYJY55555PGY~
#57?YJJYYY55GGB&BJ!~~~~~~~~~^^^^~~!7?5JY55JYYJ??????YYJGJ?J!77~~~~~!!~~~!7?YYYJJ!~~7JJ???77J?77?YY?~
&GJ!7JJ?JJJY5PPGB#PJ7!!~!~~~~~~~~!77JP55JY55?7!~^~^!7?YGJ~!J7!~~~~~~~~~~~!75BGGBP??PP5PY55PP5?!:!!~^
&&GJ!~7?7???JJJ5PGBBPJ?7!!!!!~~~!!!?Y5YY5GP7!~^:^~:^!7Y5~!55J?7!~~~~~~~~~~!7YGYPP5?YYYY!JPYJ!.:JBPY!
B##BJ!^:^!777??77JY55PPYJ?7!!!!!!7JY55YYGJ!~^^::^^.~!7JG57PBYJ?!~~^^^^^^~~~~!!^~7?!7~^:^~~^. !PBGGGG
BGGBG5J??77!~^~!777??JJJJJ?????JYYY5YJYY7~^^:::::.:~~!?5B!?5Y?7!~~~^^^^^^^^^::^^::^::::::..^5#BGGBP?
BGPPPPPGGPPYJYJ~^^^~!777?J7???JY55YJJ5?77~^^^:^::.^^^~7JPP~?JJ?7!~~~~^^^^^^:^^::::::.:...~Y##BBBBY~.
#BPP5555555PB##BPP55YY?7Y~^^!JJYY?77J?7?J?~~^^^^:^^:^~!?PPJ!?JJ?7!~~~~~~^^^^^^^::.....^?P##BBG5?^:^~
BGPP55555555555PPPGGBBBP5J7??77777!!~!7??JJ7!^^^^^^^~~?Y7?Y5??JJJ??7!!~~~~~~~^^:::^!JG##BP5J7~^!?J!^
GPP555555555555YY5PPPPPP55YJ???7777!~~~!7J5J77!~~~!7?YJ?755Y5YJJJJ??7!77777777?Y5PBBBG5J77!!!?YY!^~!
J55555555555555YY5GP555555YYYJYJ????7!!~~!7!^:~7?Y?!!7???J?!~!JJJ???!!777!7!777JJJJ?77?????JYJ!^~!!Y
7JJY5555555555555PGP555555YJYYYJ??77?7!!~^^::::~!~:.:^^~~^^^^:^~!77!777!~~^^~!~!!!!!~~7?7~~~~~!!75#&
7JJY5555555555YY5GPP555Y555YJYYJYJ?7??7~~^::^^^^::::::^^^^^^^^~~~~~^^~!^^:^7?!!~~~~~^^~~~^::!7?P&&##
?J5YYYYYYYYYYYY5PGPP5555YY55YY5555JJJJJ?7!^:^~!!~^::^!!!!!!!!777!~~~!~::!5B&&##BBBBGPPPP555PG#&&#B##
GPPG5?JJJJJJJJJ5PPPPP55555555555PPGYJYYYYY?77777!!~!???????????77?J??JYB&&&&&&&&&&&&&&&&&&&&&&#BBG5!
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract ADICK is ERC20 {
    constructor() ERC20("ADICK", "ADICK") {
        _mint(msg.sender, 9000000000000 * 10**18);
    }
}