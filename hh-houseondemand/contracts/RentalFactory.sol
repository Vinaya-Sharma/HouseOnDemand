// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RentalAgreement.sol";

contract RentalFactory {
    event RENTALFACTORY_rentalCreated(
        address rentalAddress,
        address landlord,
        address tenant
    );

    mapping(address => RentalAgreement[]) public rentalsByOwner;

    function createNewRental(
        uint256 _rent,
        address _tenant,
        uint256 _rentGurantee,
        uint256 _securityDeposit,
        address _lendingServiceAddress,
        address _tokenUsedForPayment
    ) public {
        RentalAgreement rentalAgreement = new RentalAgreement(
            _rent,
            msg.sender,
            _tenant,
            _rentGurantee,
            _securityDeposit,
            _lendingServiceAddress,
            _tokenUsedForPayment
        );

        emit RENTALFACTORY_rentalCreated(
            address(rentalAgreement),
            msg.sender,
            _tenant
        );
        rentalsByOwner[msg.sender].push(rentalAgreement);
    }
}
