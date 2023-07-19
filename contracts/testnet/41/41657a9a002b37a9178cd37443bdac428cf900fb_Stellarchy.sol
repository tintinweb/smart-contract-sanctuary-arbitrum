// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {Structs as S} from "./libraries/Structs.sol";
import {Compounds} from "./Compounds.sol";
import {ID} from "./libraries/ID.sol";
import {Lab} from "./Lab.sol";
import {Dockyard} from "./Dockyard.sol";
import {Defences} from "./Defences.sol";
import {ISTERC20} from "./tokens/STERC20.sol";
import {ISTERC721} from "./tokens/STERC721.sol";

contract Stellarchy is Compounds, Lab, Dockyard, Defences {
    uint256 public constant PRICE = 0.01 ether;

    address payable public owner;

    uint256 private numberOfPlanets;

    mapping(uint256 => uint256) private resourcesSpent;

    address private erc721Address;

    address private steelAddress;

    address private quartzAddress;

    address private tritiumAddress;

    mapping(uint256 => uint256) private resourcesTimer;

    constructor(
        address erc721,
        address steel,
        address quartz,
        address tritium
    ) {
        _initializer(erc721, steel, quartz, tritium);
    }

    receive() external payable {}

    function generatePlanet() external payable {
        ISTERC721 erc721 = ISTERC721(erc721Address);
        require(erc721.balanceOf(msg.sender) == 0, "MAX_PLANET_PER_ADDRESS");
        require(msg.value >= PRICE, "NOT_ENOUGH_ETHER");
        erc721.mint(msg.sender, numberOfPlanets + 1);
        numberOfPlanets += 1;
        _mintInitialLiquidity(msg.sender);
    }

    function steelMineUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.ERC20s memory cost = _steelMineCost(steelMineLevel[planetId]);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        steelMineLevel[planetId] += 1;
    }

    function quartzMineUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.ERC20s memory cost = _quartzMineCost(quartzMineLevel[planetId]);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        quartzMineLevel[planetId] += 1;
    }

    function tritiumMineUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.ERC20s memory cost = _tritiumMineCost(tritiumMineLevel[planetId]);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        tritiumMineLevel[planetId] += 1;
    }

    function energyPlantUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.ERC20s memory cost = _energyPlantCost(energyPlantLevel[planetId]);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        energyPlantLevel[planetId] += 1;
    }

    function dockyardUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.ERC20s memory cost = _dockyardCost(dockyardLevel[planetId]);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        dockyardLevel[planetId] += 1;
    }

    function labUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.ERC20s memory cost = _labCost(labLevel[planetId]);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        labLevel[planetId] += 1;
    }

    function energyInnovationUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        energyInnovationRequirements(labLevel[planetId]);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            energyInnovationLevel[planetId],
            techsCosts.energyInnovation
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        energyInnovationLevel[planetId] += 1;
    }

    function digitalSystemsUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        digitalSystemsRequirements(labLevel[planetId]);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            digitalSystemsLevel[planetId],
            techsCosts.digitalSystems
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        digitalSystemsLevel[planetId] += 1;
    }

    function beamTechnologyUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        beamTechnologyRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            beamTechnologyLevel[planetId],
            techsCosts.beamTechnology
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        beamTechnologyLevel[planetId] += 1;
    }

    function ionSystemsUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        ionSystemsRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            ionSystemsLevel[planetId],
            techsCosts.ionSystems
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        ionSystemsLevel[planetId] += 1;
    }

    function plasmaEngineeringUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        plasmaEngineeringRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            plasmaEngineeringLevel[planetId],
            techsCosts.plasmaEngineering
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        plasmaEngineeringLevel[planetId] += 1;
    }

    function spacetimeWarpUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        spacetimeWarpRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            spacetimeWarpLevel[planetId],
            techsCosts.spacetimeWarp
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        spacetimeWarpLevel[planetId] += 1;
    }

    function combustionDriveUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        combustiveDriveRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            combustiveDriveLevel[planetId],
            techsCosts.combustiveDrive
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        combustiveDriveLevel[planetId] += 1;
    }

    function thrustPropulsionUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        thrustPropulsionRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            thrustPropulsionLevel[planetId],
            techsCosts.thrustPropulsion
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        thrustPropulsionLevel[planetId] += 1;
    }

    function warpDriveUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        warpDriveRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            warpDriveLevel[planetId],
            techsCosts.warpDrive
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        warpDriveLevel[planetId] += 1;
    }

    function armourInnovationUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        armourRequirements(labLevel[planetId]);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            armourInnovationLevel[planetId],
            techsCosts.armourInnovation
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        armourInnovationLevel[planetId] += 1;
    }

    function armsDevelopmentUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        armsDevelopmentRequirements(labLevel[planetId]);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            armsDevelopmentLevel[planetId],
            techsCosts.armsDevelopment
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        armsDevelopmentLevel[planetId] += 1;
    }

    function shieldTechUpgrade() external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        shieldTechRequirements(labLevel[planetId], techs);
        S.TechsCost memory techsCosts = getTechsUpgradeCosts();
        S.ERC20s memory cost = techUpgradeCost(
            shieldTechLevel[planetId],
            techsCosts.shieldTech
        );
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        shieldTechLevel[planetId] += 1;
    }

    function carrierBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        carrierRequirements(dockyardLevel[planetId], techs);
        S.ShipsCost memory unitsCost = _shipsUnitCost();
        S.ERC20s memory cost = shipsCost(amount, unitsCost.carrier);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        carrierAvailable[planetId] += amount;
    }

    function celestiaBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        celestiaRequirements(dockyardLevel[planetId], techs);
        S.ShipsCost memory unitsCost = _shipsUnitCost();
        S.ERC20s memory cost = shipsCost(amount, unitsCost.celestia);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        celestiaAvailable[planetId] += amount;
    }

    function sparrowBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        sparrowRequirements(dockyardLevel[planetId]);
        S.ShipsCost memory unitsCost = _shipsUnitCost();
        S.ERC20s memory cost = shipsCost(amount, unitsCost.sparrow);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        sparrowAvailable[planetId] += amount;
    }

    function scraperBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        scraperRequirements(dockyardLevel[planetId], techs);
        S.ShipsCost memory unitsCost = _shipsUnitCost();
        S.ERC20s memory cost = shipsCost(amount, unitsCost.scraper);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        scraperAvailable[planetId] += amount;
    }

    function frigateBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        frigateRequirements(dockyardLevel[planetId], techs);
        S.ShipsCost memory unitsCost = _shipsUnitCost();
        S.ERC20s memory cost = shipsCost(amount, unitsCost.frigate);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        frigateAvailable[planetId] += amount;
    }

    function armadeBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        armadeRequirements(dockyardLevel[planetId], techs);
        S.ShipsCost memory unitsCost = _shipsUnitCost();
        S.ERC20s memory cost = shipsCost(amount, unitsCost.carrier);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        armadeAvailable[planetId] += amount;
    }

    function blasterBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        blasterRequirements(dockyardLevel[planetId]);
        S.DefencesCost memory unitsCost = _defencesUnitCost();
        S.ERC20s memory cost = defencesCost(amount, unitsCost.blaster);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        blasterAvailable[planetId] += amount;
    }

    function beamBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        beamRequirements(dockyardLevel[planetId], techs);
        S.DefencesCost memory unitsCost = _defencesUnitCost();
        S.ERC20s memory cost = defencesCost(amount, unitsCost.beam);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        beamAvailable[planetId] += amount;
    }

    function astralLauncherBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        astralLauncherRequirements(dockyardLevel[planetId], techs);
        S.DefencesCost memory unitsCost = _defencesUnitCost();
        S.ERC20s memory cost = defencesCost(amount, unitsCost.astralLauncher);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        astralLauncherAvailable[planetId] += amount;
    }

    function plasmaProjectorBuild(uint amount) external {
        collectResources();
        uint256 planetId = _getTokenOwner(msg.sender);
        S.Techs memory techs = getTechsLevels();
        plasmaProjectorRequirements(dockyardLevel[planetId], techs);
        S.DefencesCost memory unitsCost = _defencesUnitCost();
        S.ERC20s memory cost = defencesCost(amount, unitsCost.plasmaProjector);
        _payResourcesERC20(msg.sender, cost);
        _updateResourcesSpent(planetId, cost);
        plasmaAvailable[planetId] += amount;
    }

    function collectResources() public {
        uint256 planetId = _getTokenOwner(msg.sender);
        S.ERC20s memory amounts = getCollectibleResources();
        _recieveResourcesERC20(msg.sender, amounts);
        resourcesTimer[planetId] = block.timestamp;
    }

    function getTokenAddresses()
        external
        view
        returns (S.Tokens memory tokens)
    {
        S.Tokens memory _tokens;
        _tokens.erc721 = erc721Address;
        _tokens.steel = steelAddress;
        _tokens.quartz = quartzAddress;
        _tokens.tritium = tritiumAddress;
        return _tokens;
    }

    function getNumberOfPlanets() external view returns (uint256 nPlanets) {
        return numberOfPlanets;
    }

    function getPlanetPoints(
        uint256 planetId
    ) external view returns (uint256 points) {
        return resourcesSpent[planetId] / 1000;
    }

    function getSpendableResources(
    ) external view returns (S.ERC20s memory) {
        S.Interfaces memory interfaces = _getInterfaces();
        S.ERC20s memory amounts;
        amounts.steel = interfaces.steel.balanceOf(msg.sender);
        amounts.quartz = interfaces.quartz.balanceOf(msg.sender);
        amounts.tritium = interfaces.tritium.balanceOf(msg.sender);
        return amounts;
    }

    function getCollectibleResources(
) public view returns (S.ERC20s memory) {
        S.ERC20s memory _resources;
        S.Interfaces memory interfaces = _getInterfaces();
        uint256 planetId = interfaces.erc721.tokenOf(msg.sender);
        uint256 timeElapsed = _timeSinceLastCollection(planetId);
        _resources.steel =
            (_steelProduction(steelMineLevel[planetId]) * timeElapsed) /
            3600;
        _resources.quartz =
            (_quartzProduction(quartzMineLevel[planetId]) * timeElapsed) /
            3600;
        _resources.tritium =
            (_tritiumProduction(tritiumMineLevel[planetId]) * timeElapsed) /
            3600;
        return _resources;
    }

    function getEnergyAvailable() external view returns (int256 energy) {
        S.Interfaces memory interfaces = _getInterfaces();
        uint256 planetId = interfaces.erc721.tokenOf(msg.sender);
        S.Compounds memory mines = getCompoundsLevels();
        uint256 grossProduction = _energyPlantProduction(
            energyPlantLevel[planetId]
        );
        int256 energyRequired = _calculateEnergyConsumption(mines);
        return int256(grossProduction) - energyRequired;
    }

    function getCompoundsLevels() public view returns (S.Compounds memory levels) {
        S.Compounds memory compounds;
        S.Interfaces memory interfaces = _getInterfaces();
        uint256 planetId = interfaces.erc721.tokenOf(msg.sender);
        compounds.steelMine = steelMineLevel[planetId];
        compounds.quartzMine = quartzMineLevel[planetId];
        compounds.tritiumMine = tritiumMineLevel[planetId];
        compounds.energyPlant = energyPlantLevel[planetId];
        compounds.dockyard = dockyardLevel[planetId];
        compounds.lab = labLevel[planetId];
        return compounds;
    }

    function getCompoundsUpgradeCost() external view returns (S.CompoundsCost memory) {
        S.CompoundsCost memory _cost;
        S.Interfaces memory interfaces = _getInterfaces();
        uint256 planetId = interfaces.erc721.tokenOf(msg.sender);
        _cost.steelMine = _steelMineCost(steelMineLevel[planetId]);
        _cost.quartzMine = _quartzMineCost(quartzMineLevel[planetId]);
        _cost.tritiumMine = _tritiumMineCost(tritiumMineLevel[planetId]);
        _cost.energyPlant = _energyPlantCost(energyPlantLevel[planetId]);
        _cost.dockyard = _dockyardCost(dockyardLevel[planetId]);
        _cost.lab = _labCost(labLevel[planetId]);
        return _cost;
    }

    function getTechsLevels() public view returns (S.Techs memory) {
        S.Techs memory techs;
        S.Interfaces memory interfaces = _getInterfaces();
        uint256 planetId = interfaces.erc721.tokenOf(msg.sender);
        techs.energyInnovation = energyInnovationLevel[planetId];
        techs.digitalSystems = digitalSystemsLevel[planetId];
        techs.beamTechnology = beamTechnologyLevel[planetId];
        techs.armourInnovation = armourInnovationLevel[planetId];
        techs.ionSystems = ionSystemsLevel[planetId];
        techs.plasmaEngineering = plasmaEngineeringLevel[planetId];
        techs.armsDevelopment = armsDevelopmentLevel[planetId];
        techs.shieldTech = shieldTechLevel[planetId];
        techs.spacetimeWarp = spacetimeWarpLevel[planetId];
        techs.combustiveDrive = combustiveDriveLevel[planetId];
        techs.thrustPropulsion = thrustPropulsionLevel[planetId];
        techs.warpDrive = warpDriveLevel[planetId];
        return techs;
    }

    function getTechsUpgradeCosts() public view returns (S.TechsCost memory) {
        S.Techs memory techs = getTechsLevels();
        return _techsCost(techs);
    }

    function getShipsLevels(
        uint256 planeId
    ) external view returns (S.ShipsLevels memory) {
        S.ShipsLevels memory ships;
        ships.carrier = carrierAvailable[planeId];
        ships.celestia = celestiaAvailable[planeId];
        ships.scraper = scraperAvailable[planeId];
        ships.sparrow = sparrowAvailable[planeId];
        ships.frigate = frigateAvailable[planeId];
        ships.armade = armadeAvailable[planeId];
        return ships;
    }

    function getShipsCost() external pure returns (S.ShipsCost memory) {
        return _shipsUnitCost();
    }

    function getDefencesLevels(
        uint256 planeId
    ) external view returns (S.DefencesLevels memory) {
        S.DefencesLevels memory defences;
        defences.blaster = blasterAvailable[planeId];
        defences.beam = beamAvailable[planeId];
        defences.astralLauncher = astralLauncherAvailable[planeId];
        defences.plasmaProjector = plasmaAvailable[planeId];
        return defences;
    }

    function getDefencesCost() external pure returns (S.DefencesCost memory) {
        return _defencesUnitCost();
    }

    function _initializer(
        address erc721,
        address steel,
        address quartz,
        address tritium
    ) private {
        erc721Address = erc721;
        steelAddress = steel;
        quartzAddress = quartz;
        tritiumAddress = tritium;
    }

    function _getTokenOwner(address account) private view returns (uint256) {
        ISTERC721 erc721 = ISTERC721(erc721Address);
        return erc721.tokenOf(account);
    }

    function _getInterfaces() private view returns (S.Interfaces memory) {
        S.Interfaces memory interfaces;
        interfaces.erc721 = ISTERC721(erc721Address);
        interfaces.steel = ISTERC20(steelAddress);
        interfaces.quartz = ISTERC20(quartzAddress);
        interfaces.tritium = ISTERC20(tritiumAddress);
        return interfaces;
    }

    function _timeSinceLastCollection(
        uint256 planetId
    ) private view returns (uint256) {
        return block.timestamp - resourcesTimer[planetId];
    }

    function _mintInitialLiquidity(address caller) private {
        S.Interfaces memory interfaces = _getInterfaces();
        interfaces.steel.mint(caller, 500);
        interfaces.quartz.mint(caller, 300);
        interfaces.tritium.mint(caller, 100);
    }

    function _recieveResourcesERC20(
        address caller,
        S.ERC20s memory amounts
    ) private {
        S.Interfaces memory interfaces = _getInterfaces();
        if (amounts.steel > 0) {
            interfaces.steel.mint(caller, amounts.steel);
        }
        if (amounts.quartz > 0) {
            interfaces.quartz.mint(caller, amounts.quartz);
        }
        if (amounts.tritium > 0) {
            interfaces.tritium.mint(caller, amounts.tritium);
        }
    }

    function _payResourcesERC20(
        address caller,
        S.ERC20s memory amounts
    ) private {
        S.Interfaces memory interfaces = _getInterfaces();
        if (amounts.steel > 0) {
            require(
                interfaces.steel.balanceOf(caller) >= amounts.steel,
                "NOT_ENOUGH_STEEL"
            );
            interfaces.steel.burn(caller, amounts.steel);
        }
        if (amounts.quartz > 0) {
            require(
                interfaces.quartz.balanceOf(caller) >= amounts.quartz,
                "NOT_ENOUGH_QUARTZ"
            );
            interfaces.quartz.burn(caller, amounts.quartz);
        }
        if (amounts.tritium > 0) {
            require(
                interfaces.tritium.balanceOf(caller) >= amounts.tritium,
                "NOT_ENOUGH_TRITIUM"
            );
            interfaces.tritium.burn(caller, amounts.tritium);
        }
    }

    function _updateResourcesSpent(
        uint256 planetId,
        S.ERC20s memory cost
    ) private {
        resourcesSpent[planetId] += (cost.steel + cost.quartz);
    }

    function _calculateEnergyConsumption(
        S.Compounds memory mines
    ) private pure returns (int256) {
        return
            int256(
                _baseMineConsumption(mines.steelMine) +
                    _baseMineConsumption(mines.quartzMine) +
                    _tritiumMineConsumption(mines.tritiumMine)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {ISTERC20} from "../tokens/STERC20.sol";
import {ISTERC721} from "../tokens/STERC721.sol";

library Structs {
    struct ERC20s {
        uint256 steel;
        uint256 quartz;
        uint256 tritium;
    }

    struct Techs {
        uint256 energyInnovation;
        uint256 digitalSystems;
        uint256 beamTechnology;
        uint256 ionSystems;
        uint256 plasmaEngineering;
        uint256 spacetimeWarp;
        uint256 combustiveDrive;
        uint256 thrustPropulsion;
        uint256 warpDrive;
        uint256 armourInnovation;
        uint256 armsDevelopment;
        uint256 shieldTech;
    }

    struct TechsCost {
        ERC20s energyInnovation;
        ERC20s digitalSystems;
        ERC20s beamTechnology;
        ERC20s ionSystems;
        ERC20s plasmaEngineering;
        ERC20s spacetimeWarp;
        ERC20s combustiveDrive;
        ERC20s thrustPropulsion;
        ERC20s warpDrive;
        ERC20s armourInnovation;
        ERC20s armsDevelopment;
        ERC20s shieldTech;
    }

    struct ShipsLevels {
        uint256 carrier;
        uint256 celestia;
        uint256 scraper;
        uint256 sparrow;
        uint256 frigate;
        uint256 armade;
    }

    struct ShipsCost {
        ERC20s carrier;
        ERC20s celestia;
        ERC20s scraper;
        ERC20s sparrow;
        ERC20s frigate;
        ERC20s armade;
    }

    struct DefencesLevels {
        uint blaster;
        uint256 beam;
        uint256 astralLauncher;
        uint256 plasmaProjector;
    }

    struct DefencesCost {
        ERC20s blaster;
        ERC20s beam;
        ERC20s astralLauncher;
        ERC20s plasmaProjector;
    }

    struct Tokens {
        address erc721;
        address steel;
        address quartz;
        address tritium;
    }

    struct Compounds {
        uint256 steelMine;
        uint256 quartzMine;
        uint256 tritiumMine;
        uint256 energyPlant;
        uint256 dockyard;
        uint256 lab;
    }

    struct CompoundsCost {
        ERC20s steelMine;
        ERC20s quartzMine;
        ERC20s tritiumMine;
        ERC20s energyPlant;
        ERC20s dockyard;
        ERC20s lab;
    }

    struct Interfaces {
        ISTERC721 erc721;
        ISTERC20 steel;
        ISTERC20 quartz;
        ISTERC20 tritium;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {Structs} from "./libraries/Structs.sol";

contract Compounds {
    mapping(uint256 => uint256) public steelMineLevel;

    mapping(uint256 => uint256) public quartzMineLevel;

    mapping(uint256 => uint256) public tritiumMineLevel;

    mapping(uint256 => uint256) public energyPlantLevel;

    mapping(uint256 => uint256) public dockyardLevel;

    mapping(uint256 => uint256) public labLevel;

    function _steelMineCost(
        uint256 currentLevel
    ) internal pure returns (Structs.ERC20s memory) {
        Structs.ERC20s memory cost;
        cost.steel = (60 * (15 ** currentLevel)) / 10 ** currentLevel;
        cost.quartz = (15 * (15 ** currentLevel)) / 10 ** currentLevel;
        return cost;
    }

    function _quartzMineCost(
        uint256 currentLevel
    ) internal pure returns (Structs.ERC20s memory) {
        Structs.ERC20s memory cost;
        cost.steel = (48 * (16 ** currentLevel)) / 10 ** currentLevel;
        cost.quartz = (24 * (16 ** currentLevel)) / 10 ** currentLevel;
        return cost;
    }

    function _tritiumMineCost(
        uint256 currentLevel
    ) internal pure returns (Structs.ERC20s memory) {
        Structs.ERC20s memory cost;
        cost.steel = (225 * (15 ** currentLevel)) / 10 ** currentLevel;
        cost.quartz = (75 * (15 ** currentLevel)) / 10 ** currentLevel;
        return cost;
    }

    function _energyPlantCost(
        uint256 currentLevel
    ) internal pure returns (Structs.ERC20s memory) {
        Structs.ERC20s memory cost;
        cost.steel = (75 * (15 ** currentLevel)) / 10 ** currentLevel;
        cost.quartz = (30 * (15 ** currentLevel)) / 10 ** currentLevel;
        return cost;
    }

    function _dockyardCost(
        uint256 currentLevel
    ) internal pure returns (Structs.ERC20s memory) {
        Structs.ERC20s memory cost;
        cost.steel = 400 * 2 ** currentLevel;
        cost.quartz = 200 * 2 ** currentLevel;
        cost.tritium = 100 * 2 ** currentLevel;
        return cost;
    }

    function _labCost(
        uint256 currentLevel
    ) internal pure returns (Structs.ERC20s memory) {
        Structs.ERC20s memory cost;
        cost.steel = 200 * 2 ** currentLevel;
        cost.quartz = 400 * 2 ** currentLevel;
        cost.tritium = 200 * 2 ** currentLevel;
        return cost;
    }

    function _steelProduction(
        uint256 currentLevel
    ) internal pure returns (uint256) {
        return (30 * currentLevel * 11 ** currentLevel) / 10 ** currentLevel;
    }

    function _quartzProduction(
        uint256 currentLevel
    ) internal pure returns (uint256) {
        return (20 * currentLevel * 11 ** currentLevel) / 10 ** currentLevel;
    }

    function _tritiumProduction(
        uint256 currentLevel
    ) internal pure returns (uint256) {
        return (10 * currentLevel * 11 ** currentLevel) / 10 ** currentLevel;
    }

    function _energyPlantProduction(
        uint256 currentLevel
    ) internal pure returns (uint256) {
        return (20 * currentLevel * 11 ** currentLevel) / 10 ** currentLevel;
    }

    function _baseMineConsumption(
        uint256 currentLevel
    ) internal pure returns (uint256) {
        return (10 * currentLevel * 11 ** currentLevel) / 10 ** currentLevel;
    }

    function _tritiumMineConsumption(
        uint256 currentLevel
    ) internal pure returns (uint256) {
        return (20 * currentLevel * 11 ** currentLevel) / 10 ** currentLevel;
    }

    function _productionScaler(
        uint256 production,
        uint256 available,
        uint256 required
    ) internal pure returns (uint256) {
        if (available > required) {
            return production;
        } else {
            return (((available * 100) / required) * production) / 100;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

library ID {
    uint256 public constant ENERGY_INNOVATION = 1;
    uint256 public constant DIGITAL_SYSTEMS = 2;
    uint256 public constant BEAM_TECHNOLOGY = 3;
    uint256 public constant ION_SYSTEMS = 4;
    uint256 public constant PLASMA_ENGINEERING = 5;
    uint256 public constant SPACETIME_WARP = 6;
    uint256 public constant COMBUSTIVE_DRIVE = 7;
    uint256 public constant THRUST_PROPULSION = 8;
    uint256 public constant WARP_DRIVE = 9;
    uint256 public constant ARMOUR_INNOVATION = 10;
    uint256 public constant ARMS_DEVELOPMENT = 11;
    uint256 public constant SHIELD_TECH = 12;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {Structs as S} from "./libraries/Structs.sol";
import {ID} from "./libraries/ID.sol";

contract Lab {
    mapping(uint256 => uint256) internal energyInnovationLevel;

    mapping(uint256 => uint256) internal digitalSystemsLevel;

    mapping(uint256 => uint256) internal beamTechnologyLevel;

    mapping(uint256 => uint256) internal armourInnovationLevel;

    mapping(uint256 => uint256) internal ionSystemsLevel;

    mapping(uint256 => uint256) internal plasmaEngineeringLevel;

    mapping(uint256 => uint256) internal stellarPhysicsLevel;

    mapping(uint256 => uint256) internal armsDevelopmentLevel;

    mapping(uint256 => uint256) internal shieldTechLevel;

    mapping(uint256 => uint256) internal spacetimeWarpLevel;

    mapping(uint256 => uint256) internal combustiveDriveLevel;

    mapping(uint256 => uint256) internal thrustPropulsionLevel;

    mapping(uint256 => uint256) internal warpDriveLevel;

    function techUpgradeCost(
        uint256 currentLevel,
        S.ERC20s memory cost
    ) internal pure returns (S.ERC20s memory) {
        S.ERC20s memory _cost;
        _cost.steel = cost.steel * 2 ** currentLevel;
        _cost.quartz = cost.quartz * 2 ** currentLevel;
        _cost.tritium = cost.tritium * 2 ** currentLevel;
        return _cost;
    }

    function energyInnovationRequirements(uint256 labLevel) internal pure {
        require(labLevel >= 1, "Level 1 Lab req");
    }

    function digitalSystemsRequirements(uint256 labLevel) internal pure {
        require(labLevel >= 1, "Level 1 Lab req");
    }

    function beamTechnologyRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 1, "Level 1 Lab req");
        require(techs.energyInnovation >= 1, "Level 1 Energy Innovation req");
    }

    function armourRequirements(uint256 labLevel) internal pure {
        require(labLevel >= 2, "Level 2 Lab req");
    }

    function ionSystemsRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 4, "Level 4 Lab req");
        require(techs.beamTechnology >= 5, "Level 5 Beam tech req");
        require(techs.energyInnovation >= 4, "Level 4 Energy Innovation  req");
    }

    function plasmaEngineeringRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 4, "Level 4 Lab req");
        require(techs.beamTechnology >= 10, "Level 10 Beam Tech req");
        require(techs.energyInnovation >= 8, "Level 8 Energy Innovation  req");
        require(techs.spacetimeWarp >= 5, "Level 5 Spacetime Warp req");
    }

    function armsDevelopmentRequirements(uint256 labLevel) internal pure {
        require(labLevel >= 4, "Level 4 Lab req");
    }

    function shieldTechRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 6, "Level 6 Lab req");
        require(techs.energyInnovation >= 6, "Level 6 Energy Innovation  req");
    }

    function spacetimeWarpRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 7, "Level 7 Lab req");
        require(techs.energyInnovation >= 5, "Level 5 Energy Innovation  req");
        require(techs.shieldTech >= 5, "Level 5 Shield Tech req");
    }

    function combustiveDriveRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 1, "Level 1 Lab req");
        require(techs.energyInnovation >= 1, "Level 1 Energy Innovation  req");
    }

    function thrustPropulsionRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 2, "Level 2 Lab req");
        require(techs.energyInnovation >= 1, "Level 1 Energy Innovation  req");
    }

    function warpDriveRequirements(
        uint256 labLevel,
        S.Techs memory techs
    ) internal pure {
        require(labLevel >= 7, "Level 7 Lab req");
        require(techs.energyInnovation >= 5, "Level 5 Energy Innovation  req");
        require(techs.spacetimeWarp >= 3, "Level 3 Spacetime Warp req");
    }

    function techCost(uint id) internal pure returns (S.ERC20s memory) {
        S.ERC20s memory cost;
        if (id == ID.ENERGY_INNOVATION) {
            cost.quartz = 800;
            cost.tritium = 400;
        } else if (id == ID.DIGITAL_SYSTEMS) {
            cost.quartz = 400;
            cost.tritium = 600;
        } else if (id == ID.BEAM_TECHNOLOGY) {
            cost.quartz = 800;
            cost.tritium = 400;
        } else if (id == ID.ION_SYSTEMS) {
            cost.steel = 1000;
            cost.quartz = 300;
            cost.tritium = 1000;
        } else if (id == ID.PLASMA_ENGINEERING) {
            cost.steel = 2000;
            cost.quartz = 4000;
            cost.tritium = 1000;
        } else if (id == ID.SPACETIME_WARP) {
            cost.quartz = 4000;
            cost.tritium = 2000;
        } else if (id == ID.COMBUSTIVE_DRIVE) {
            cost.steel = 400;
            cost.tritium = 600;
        } else if (id == ID.THRUST_PROPULSION) {
            cost.steel = 2000;
            cost.quartz = 4000;
            cost.tritium = 600;
        } else if (id == ID.WARP_DRIVE) {
            cost.steel = 10000;
            cost.quartz = 2000;
            cost.tritium = 6000;
        } else if (id == ID.ARMOUR_INNOVATION) {
            cost.steel = 1000;
        } else if (id == ID.ARMS_DEVELOPMENT) {
            cost.steel = 800;
            cost.quartz = 200;
        } else if (id == ID.SHIELD_TECH) {
            cost.steel = 200;
            cost.quartz = 600;
        }
        return cost;
    }

    function _techsCost(
        S.Techs memory techs
    ) internal pure returns (S.TechsCost memory) {
        S.TechsCost memory cost;
        cost.energyInnovation = techUpgradeCost(
            techs.energyInnovation,
            techCost(ID.ENERGY_INNOVATION)
        );
        cost.digitalSystems = techUpgradeCost(
            techs.digitalSystems,
            techCost(ID.DIGITAL_SYSTEMS)
        );
        cost.beamTechnology = techUpgradeCost(
            techs.beamTechnology,
            techCost(ID.BEAM_TECHNOLOGY)
        );
        cost.armourInnovation = techUpgradeCost(
            techs.armourInnovation,
            techCost(ID.ARMOUR_INNOVATION)
        );
        cost.ionSystems = techUpgradeCost(
            techs.ionSystems,
            techCost(ID.ION_SYSTEMS)
        );
        cost.plasmaEngineering = techUpgradeCost(
            techs.plasmaEngineering,
            techCost(ID.PLASMA_ENGINEERING)
        );
        cost.armsDevelopment = techUpgradeCost(
            techs.armsDevelopment,
            techCost(ID.ARMS_DEVELOPMENT)
        );
        cost.shieldTech = techUpgradeCost(
            techs.shieldTech,
            techCost(ID.SHIELD_TECH)
        );
        cost.spacetimeWarp = techUpgradeCost(
            techs.spacetimeWarp,
            techCost(ID.SPACETIME_WARP)
        );
        cost.combustiveDrive = techUpgradeCost(
            techs.combustiveDrive,
            techCost(ID.COMBUSTIVE_DRIVE)
        );
        cost.thrustPropulsion = techUpgradeCost(
            techs.thrustPropulsion,
            techCost(ID.THRUST_PROPULSION)
        );
        cost.warpDrive = techUpgradeCost(
            techs.warpDrive,
            techCost(ID.WARP_DRIVE)
        );
        return cost;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {Structs as S} from "./libraries/Structs.sol";

contract Dockyard {
    mapping(uint256 => uint256) internal carrierAvailable;

    mapping(uint256 => uint256) internal scraperAvailable;

    mapping(uint256 => uint256) internal celestiaAvailable;

    mapping(uint256 => uint256) internal sparrowAvailable;

    mapping(uint256 => uint256) internal frigateAvailable;

    mapping(uint256 => uint256) internal armadeAvailable;

    function shipsCost(
        uint256 quantity,
        S.ERC20s memory _cost
    ) internal pure returns (S.ERC20s memory) {
        S.ERC20s memory cost;
        cost.steel = _cost.steel * quantity;
        cost.quartz = _cost.quartz * quantity;
        cost.tritium = _cost.tritium * quantity;
        return (cost);
    }

    function carrierRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 2, "Level 2 Dockyard is req");
        require(techs.combustiveDrive >= 2, "Level 2 Combustive Engine req");
    }

    function celestiaRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 1, "Level 1 Dockyard is req");
        require(techs.combustiveDrive >= 1, "Level 1 Combustive Drive req");
    }

    function scraperRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 4, "Level 4 Dockyard is req");
        require(techs.combustiveDrive >= 6, "Level 6 Combustive Engine req");
        require(techs.shieldTech >= 2, "Level 2 Shield Tech req");
    }

    function sparrowRequirements(uint256 dockyardLevel) internal pure {
        require(dockyardLevel >= 2, "Level 2 Dockyard is req");
    }

    function frigateRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 5, "Level 5 Dockyard is req");
        require(techs.ionSystems >= 2, "Level 2 Ion Systems req");
        require(techs.thrustPropulsion >= 4, "Level 4 Thrust prop req");
    }

    function armadeRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 7, "Level 7 Dockyard is req");
        require(techs.warpDrive >= 4, "Level 4 Warp Drive req");
    }

    function _shipsUnitCost() internal pure returns (S.ShipsCost memory) {
        S.ShipsCost memory costs;
        costs.carrier.steel = 4000;
        costs.carrier.quartz = 4000;

        costs.celestia.quartz = 2000;
        costs.celestia.tritium = 500;

        costs.sparrow.steel = 6000;
        costs.sparrow.quartz = 4000;

        costs.scraper.steel = 10000;
        costs.scraper.quartz = 6000;
        costs.scraper.tritium = 2000;

        costs.frigate.steel = 20000;
        costs.frigate.quartz = 7000;
        costs.frigate.tritium = 2000;

        costs.armade.steel = 45000;
        costs.armade.quartz = 15000;
        return costs;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {Structs as S} from "./libraries/Structs.sol";

contract Defences {
    mapping(uint256 => uint256) internal blasterAvailable;

    mapping(uint256 => uint256) internal beamAvailable;

    mapping(uint256 => uint256) internal astralLauncherAvailable;

    mapping(uint256 => uint256) internal plasmaAvailable;

    function defencesCost(
        uint256 quantity,
        S.ERC20s memory _cost
    ) internal pure returns (S.ERC20s memory) {
        S.ERC20s memory cost;
        cost.steel = _cost.steel * quantity;
        cost.quartz = _cost.quartz * quantity;
        cost.tritium = _cost.tritium * quantity;
        return cost;
    }

    function blasterRequirements(uint256 dockyardLevel) internal pure {
        require(dockyardLevel >= 1, "Level 1 Dockyard is required");
    }

    function beamRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 2, "Level 2 Dockyard is required");
        require(techs.energyInnovation >= 2, "Level 2 Energy tech required");
        require(techs.beamTechnology >= 3, "Level 3 Beam Tech required");
    }

    function astralLauncherRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 6, "Level 6 Dockyard is required");
        require(techs.energyInnovation >= 6, "Level 6 Energy tech required");
        require(techs.armourInnovation >= 3, "Level 3 Armour tech required");
        require(techs.shieldTech >= 1, "Level 1 Shield Tech required");
    }

    function plasmaProjectorRequirements(
        uint256 dockyardLevel,
        S.Techs memory techs
    ) internal pure {
        require(dockyardLevel >= 8, "Level 8 Dockyard is required");
        require(techs.plasmaEngineering >= 7, "Level 7 Plasma tech required");
    }

    function _defencesUnitCost() internal pure returns (S.DefencesCost memory) {
        S.DefencesCost memory costs;
        costs.blaster.steel = 2000;

        costs.beam.steel = 6000;
        costs.beam.quartz = 2000;

        costs.astralLauncher.steel = 20000;
        costs.astralLauncher.quartz = 15000;
        costs.astralLauncher.steel = 2000;

        costs.plasmaProjector.steel = 50000;
        costs.plasmaProjector.quartz = 50000;
        costs.plasmaProjector.tritium = 3000;

        return costs;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface ISTERC20 is IERC20 {
    function mint(address caller, uint256 amount) external;

    function burn(address caller, uint256 amount) external;
}

contract STERC20 is ERC20, Ownable {
    address private _minter;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function setMinter(address minter) external virtual onlyOwner {
        _minter = minter;
    }

    function mint(address caller, uint256 amount) external virtual {
        require(msg.sender == _minter, "caller is not minter");
        _mint(caller, amount);
    }

    function burn(address caller, uint256 amount) external virtual {
        require(msg.sender == _minter, "caller is not minter");
        _burn(caller, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19 .0;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

interface ISTERC721 is IERC721 {
    function mint(address to, uint256 tokenId) external;

    function tokenOf(address account) external view returns (uint256 tokeId);
}

contract STERC721 is ERC721, Ownable {
    string private _baseTokenURI;

    address private _minter;

    mapping(address => uint256) private _tokens;

    constructor(
        string memory baseTokenURI
    ) ERC721("Stellarchy Planet", "STPL") {
        _baseTokenURI = baseTokenURI;
    }

    function mint(address to, uint256 tokenId) external virtual {
        require(msg.sender == _minter, "caller is not minter");
        require(balanceOf(to) == 0, "max planets per address is 1");
        _tokens[to] = tokenId;
        _safeMint(to, tokenId);
    }

    function setMinter(address minter) external virtual onlyOwner {
        _minter = minter;
    }

    function baseURI() external view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function tokenOf(address account) external view returns (uint256 tokenId) {
        return _tokens[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}