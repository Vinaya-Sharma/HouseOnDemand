// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RentalAgreement {
    using SafeERC20 for IERC20;

    error RENTALAGREEMENT_INCOMPLETECONSTRUCTORARGUMENTS();
    error RENTALAGREEMENT_FUNCTIONRESTRICTEDTOTENANT();
    error RENTALAGREEMENT_FUNCTIONRESTRICTEDTOLANDLORD();

    uint256 public rent;
    address public landlord;
    address public tenant;
    uint256 public rentGurantee;
    uint256 public securityDeposit;
    address public lendingServiceAddress;
    IERC20 public tokenUsedForPayment;

    constructor(
        uint256 _rent,
        address _landlord,
        address _tenant,
        uint256 _rentGurantee,
        uint256 _securityDeposit,
        address _lendingServiceAddress,
        address _tokenUsedForPayment
    ) {
        if (
            _rent == 0 ||
            _landlord == address(0) ||
            _tenant == address(0) ||
            _rentGurantee == 0 ||
            _securityDeposit == 0 ||
            _lendingServiceAddress == address(0)
        ) {
            revert RENTALAGREEMENT_INCOMPLETECONSTRUCTORARGUMENTS();
        }
        rent = _rent;
        landlord = _landlord;
        tenant = _tenant;
        rentGurantee = _rentGurantee;
        securityDeposit = _securityDeposit;
        lendingServiceAddress = _lendingServiceAddress;
        tokenUsedForPayment = IERC20(_tokenUsedForPayment);
    }

    //modifiers
    modifier onlyTenant() {
        if (msg.sender != tenant) {
            revert RENTALAGREEMENT_FUNCTIONRESTRICTEDTOTENANT();
        }
        _;
    }

    modifier onlyLandlord() {
        if (msg.sender != landlord) {
            revert RENTALAGREEMENT_FUNCTIONRESTRICTEDTOLANDLORD();
        }
        _;
    }
}
