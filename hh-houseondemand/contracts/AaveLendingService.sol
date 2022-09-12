// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ILendingService.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Interfaces/ILendingPool.sol";

contract AaveLendingService is ILendingService {
    using SafeERC20 for IERC20;

    IERC20 public aToken;
    IERC20 public tokenUsedForPayment;
    address payable public owner;

    //change address to correct chain -> shouldnt be hardcoded goerli
    ILendingPool internal i_aaveLendingPool =
        ILendingPool(0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210);

    uint256 public depositedAmountBalance;

    // this shouldn't be harcoded -> change to programatically get aTokenAddress with lending pool
    address public aDaiTokenAddress;

    //errors
    error AAVELENDINGSERVICE_RESTRICTEDTOOWNERONLY();
    error AAVELENDINGSERVICE_UNDEFINEDNEWOWNER();
    error AAVELENDINGSERVICE_NOTENOUGHTOKENS();

    constructor(address _tokenUsedForPayment) {
        tokenUsedForPayment = IERC20(_tokenUsedForPayment);
        aToken = IERC20(aDaiTokenAddress);
        aDaiTokenAddress = i_aaveLendingPool
            .getReserveData(_tokenUsedForPayment)
            .aTokenAddress;
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
        depositedAmountBalance += amount;
        if (amount > tokenUsedForPayment.balanceOf(address(this))) {
            revert AAVELENDINGSERVICE_NOTENOUGHTOKENS();
        }
        tokenUsedForPayment.approve(address(i_aaveLendingPool), amount);
        i_aaveLendingPool.deposit(
            address(tokenUsedForPayment),
            amount,
            address(this),
            0
        );
    }

    function withdraw(uint256 amount)
        external
        override(ILendingService)
        onlyOwner
    {
        depositedAmountBalance -= amount;
        uint256 aTokenAmount = aToken.balanceOf(address(this));
        if (aTokenAmount < amount) {
            revert AAVELENDINGSERVICE_NOTENOUGHTOKENS();
        }
        aToken.approve(address(i_aaveLendingPool), amount);
    }

    function depositedBalance()
        external
        view
        override(ILendingService)
        onlyOwner
        returns (uint256)
    {
        return depositedAmountBalance;
    }

    function withdrawCapitalAndInterests() external override(ILendingService) {
        depositedAmountBalance = 0;
        uint256 aTokenBalance = aToken.balanceOf(address(this));
        aToken.approve(address(i_aaveLendingPool), aTokenBalance);
        i_aaveLendingPool.withdraw(
            address(tokenUsedForPayment),
            aTokenBalance,
            address(this)
        );
        tokenUsedForPayment.safeTransfer(
            msg.sender,
            tokenUsedForPayment.balanceOf(address(this))
        );
    }
}
