// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ILendingService.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Interfaces/ILendingPool.sol";

contract MockLendingService is ILendingService {
    using SafeERC20 for IERC20;

    uint256 public amountDeposited;
    IERC20 public tokenUsedForPayment;
    address payable public owner;

    //errors
    error AAVELENDINGSERVICE_RESTRICTEDTOOWNERONLY();
    error AAVELENDINGSERVICE_UNDEFINEDNEWOWNER();
    error AAVELENDINGSERVICE_NOTENOUGHTOKENS();

    constructor(address _tokenUsedForPayment) {
        tokenUsedForPayment = IERC20(_tokenUsedForPayment);
        owner = payable(msg.sender);
    }

    //modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert AAVELENDINGSERVICE_RESTRICTEDTOOWNERONLY();
        }
        _;
    }

    //functions
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner == address(0)) {
            revert AAVELENDINGSERVICE_UNDEFINEDNEWOWNER();
        }
        owner = payable(_newOwner);
    }

    /// @notice deposits `amount` of funds to aaveLending pool
    /// @dev increments the depositedAmountBalance
    function deposit(uint256 amount)
        external
        override(ILendingService)
        onlyOwner
    {
        tokenUsedForPayment.safeTransferFrom(msg.sender, address(this), amount);
        amountDeposited += amount;
    }

    function withdraw(uint256 amount)
        external
        override(ILendingService)
        onlyOwner
    {
        if (amount > amountDeposited) {
            revert AAVELENDINGSERVICE_NOTENOUGHTOKENS();
        }
        tokenUsedForPayment.safeTransfer(msg.sender, amount);
        amountDeposited -= amount;
    }

    function depositedBalance()
        external
        view
        override(ILendingService)
        onlyOwner
        returns (uint256)
    {
        return amountDeposited;
    }

    function withdrawCapitalAndInterests() external override(ILendingService) {
        tokenUsedForPayment.safeTransfer(
            msg.sender,
            tokenUsedForPayment.balanceOf(address(this))
        );
        amountDeposited = 0;
    }
}
