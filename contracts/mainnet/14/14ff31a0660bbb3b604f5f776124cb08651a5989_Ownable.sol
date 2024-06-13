/**
 *Submitted for verification at Arbiscan.io on 2024-06-12
*/

pragma solidity ^0.4.17;

// Contrat Ownable pour gérer les autorisations
contract Ownable {
    address public owner;

    // Événement déclenché lorsqu'un transfert de propriété a lieu
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modificateur qui ne permet l'exécution de la fonction qu'au propriétaire du contrat
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Constructeur du contrat, définit le créateur comme propriétaire initial
    function Ownable() public {
        owner = msg.sender;
    }

    // Fonction permettant de transférer la propriété du contrat à une nouvelle adresse
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// Contrat TetherToken pour le token USDT
contract TetherToken is Ownable {
    string public name = "TetherToken"; // Nom du token
    string public symbol = "USDT"; // Symbole du token
    uint8 public decimals = 18; // Nombre de décimales

    uint256 public totalSupply; // Total des tokens disponibles

    mapping(address => uint256) public balanceOf; // Mapping des soldes des utilisateurs
    mapping(address => mapping(address => uint256)) public allowance; // Autorisations de dépense des tokens

    // Événement déclenché lorsqu'un transfert de tokens a lieu
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Événement déclenché lorsqu'une autorisation de dépense de tokens est accordée
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructeur du contrat, initialise le totalSupply avec le solde initial de l'adresse du déploiement du contrat
    function TetherToken(uint256 initialSupply) public {
        totalSupply = initialSupply * 10 ** uint256(decimals); // Convertit l'initialSupply en unités de token en prenant en compte le nombre de décimales
        balanceOf[msg.sender] = totalSupply; // Donne le solde initial au créateur du contrat
    }

    // Fonction de transfert de tokens
    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value); // Vérifie si l'expéditeur a suffisamment de tokens
        require(balanceOf[to] + value >= balanceOf[to]); // Vérifie le dépassement de capacité
        balanceOf[msg.sender] -= value; // Soustrait les tokens de l'expéditeur
        balanceOf[to] += value; // Ajoute les tokens au destinataire
        Transfer(msg.sender, to, value); // Déclenche l'événement de transfert
    }

    // Fonction d'autorisation de dépense de tokens
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value; // Enregistre l'autorisation de dépense dans le mapping allowance
        Approval(msg.sender, spender, value); // Déclenche l'événement d'approbation
        return true;
    }

    // Fonction de transfert de tokens de l'expéditeur à un autre adresse, en utilisant une autorisation préalable
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= allowance[from][msg.sender]); // Vérifie si le montant à transférer est inférieur ou égal à l'autorisation accordée
        require(value <= balanceOf[from]); // Vérifie si l'expéditeur a suffisamment de tokens
        require(balanceOf[to] + value >= balanceOf[to]); // Vérifie le dépassement de capacité
        balanceOf[from] -= value; // Soustrait les tokens de l'expéditeur
        balanceOf[to] += value; // Ajoute les tokens au destinataire
        allowance[from][msg.sender] -= value; // Soustrait le montant transféré de l'autorisation
        Transfer(from, to, value); // Déclenche l'événement de transfert
        return true;
    }
}