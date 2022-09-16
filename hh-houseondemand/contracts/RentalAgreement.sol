// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ILendingService.sol";

contract RentalAgreement {
    using SafeERC20 for IERC20;

    //events
    event RENTALAGREEMENT_tenantEnteredAgreement(
        uint256 depositLocked,
        uint256 rentGuranteeLocked,
        uint256 firstMonthRentPaid
    );

    //error
    error RENTALAGREEMENT_INCOMPLETECONSTRUCTORARGUMENTS();
    error RENTALAGREEMENT_FUNCTIONRESTRICTEDTOTENANT();
    error RENTALAGREEMENT_FUNCTIONRESTRICTEDTOLANDLORD();
    error RENTALAGREEMENT_termsDoNotMatch();

    //variables
    uint256 public rent;
    address public landlord;
    address public tenant;
    uint256 public rentGurantee;
    uint256 public securityDeposit;
    ILendingService public lendingServiceAddress;
    IERC20 public tokenUsedForPayment;

    //varibles for entering agreement
    uint256 public nextTimestamp;

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
        lendingServiceAddress = ILendingService(_lendingServiceAddress);
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

    function enterAgreementAsTenant(
        uint256 _rent,
        address _landlord,
        uint256 _rentGurantee,
        uint256 _securityDeposit
    ) public onlyTenant {
        //check if terms match agreement
        if (
            _rent != rent ||
            _landlord != landlord ||
            _rentGurantee != _rentGurantee ||
            securityDeposit != _securityDeposit
        ) {
            revert RENTALAGREEMENT_termsDoNotMatch();
        }

        //transfer rentGurantee + security deposit to aave lending service
        uint256 totalDeposit = _rentGurantee + _securityDeposit;
        tokenUsedForPayment.safeTransferFrom(
            tenant,
            address(this),
            totalDeposit
        );
        tokenUsedForPayment.approve(
            address(lendingServiceAddress),
            totalDeposit
        );
        lendingServiceAddress.deposit(totalDeposit);

        //transfer first months rent to landlord
        tokenUsedForPayment.safeTransferFrom(tenant, landlord, _rent);
        nextTimestamp = block.timestamp + 4 weeks;

        emit RENTALAGREEMENT_tenantEnteredAgreement(
            _securityDeposit,
            _rentGurantee,
            _rent
        );
    }
}
