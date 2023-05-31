// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error DeliveryContract__NotEnoughETHEntered();
error DeliveryContract__DriverNotRegistered();
error DeliveryContract__PackageNotExist();
error DeliveryContract__PackageAlreadyAssigned();
error DeliveryContract__NotAllowedToSignOffPackage();
error DeliveryContract__PackageAlreadyDelivered();

contract DeliveryContract {
    /* type declarations */
    struct Location {
        string longitude;
        string latitude;
        string detail;
    }

    struct Package {
        address requester;
        address driver;
        uint256 paymentAmount;
        string locationFrom;
        string locationTo;
        string notes;
        bool requesterSignedOff;
        bool driverSignedOff;
    }

    /* state variables */
    uint256 private s_minimumPayment;
    uint256 private s_nextPackageId;
    mapping(address => bool) private s_registeredDrivers;
    mapping(uint256 => Package) private s_packagesMap;

    /* Functions */
    constructor() {
        s_minimumPayment = 1e15; // 0.001, hardcoded min value for now, allow contract owner to change in the future
        s_nextPackageId = 1;
    }

    receive() external payable {
        // ...
    }

    fallback() external {
        // ...
    }

    /**
     * register after driver signed T&C
     */
    function registerDriver() public {
        s_registeredDrivers[msg.sender] = true;
    }

    function createPackage(
        string memory _locationFrom,
        string memory _locationTo,
        string memory _notes
    ) public payable returns (uint256) {
        if (msg.value < s_minimumPayment) {
            revert DeliveryContract__NotEnoughETHEntered();
        }

        uint256 packageId = s_nextPackageId;
        s_packagesMap[packageId] = Package({
            requester: msg.sender,
            driver: address(0),
            paymentAmount: msg.value,
            locationFrom: _locationFrom,
            locationTo: _locationTo,
            notes: _notes,
            requesterSignedOff: false,
            driverSignedOff: false
        });
        s_nextPackageId++;

        return (packageId);
    }

    function acceptPackage(uint256 _packageId) public {
        if (!s_registeredDrivers[msg.sender]) {
            revert DeliveryContract__DriverNotRegistered();
        }

        Package storage package = s_packagesMap[_packageId];
        if (package.requester == address(0)) {
            revert DeliveryContract__PackageNotExist();
        }

        if (package.driver != address(0)) {
            revert DeliveryContract__PackageAlreadyAssigned();
        }

        package.driver = msg.sender;
    }

    function signOffDelivery(uint256 _packageId) public {
        Package storage package = s_packagesMap[_packageId];
        if (package.requester == address(0)) {
            revert DeliveryContract__PackageNotExist();
        }

        if (msg.sender != package.requester && msg.sender != package.driver) {
            revert DeliveryContract__NotAllowedToSignOffPackage();
        }

        if (package.requesterSignedOff && package.driverSignedOff) {
            revert DeliveryContract__PackageAlreadyDelivered();
        }

        if (msg.sender == package.requester) {
            package.requesterSignedOff = true;
        }

        if (msg.sender == package.driver) {
            package.driverSignedOff = true;
        }

        if (package.requesterSignedOff && package.driverSignedOff) {
            (bool sent, ) = package.driver.call{value: package.paymentAmount}(
                ""
            );
            require(sent, "Failed to send Ether");
        }
    }

    /* view/pure functions */
    function getMinimumPayment() public view returns (uint256) {
        return s_minimumPayment;
    }

    function getNextPackageId() public view returns (uint256) {
        return s_nextPackageId;
    }

    function isDriverRegistered(address _driver) public view returns (bool) {
        return s_registeredDrivers[_driver];
    }

    function getPackage(
        uint256 packageId
    ) public view returns (Package memory) {
        return s_packagesMap[packageId];
    }
}