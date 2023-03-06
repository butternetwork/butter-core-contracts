// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interface/ISwap.sol";
import "../interface/IERC20.sol";
import "../interface/IUniRouter01.sol";
import "../interface/IV3SwapRouter.sol";
import "../interface/IWETH9.sol";
import "../libs/TransferHelper.sol";
import "../libs/SafeMath.sol";

contract UniV3ForkSwap is ISwap {


    function filterSwap(
        address router,
        bytes memory exchangeData
    ) external payable override returns (uint256) {
        uint256 amountInArr;
        uint256 amountOutMinArr;
        bytes memory pathArr;
        address to;
        address inputAddre;
        address outAddre;
        (amountInArr, amountOutMinArr, pathArr, to, inputAddre, outAddre) = abi
            .decode(
                exchangeData,
                (uint256, uint256, bytes, address, address, address)
            );
        return
            swapInputV3(
                router,
                pathArr,
                to,
                amountInArr,
                amountOutMinArr,
                inputAddre,
                outAddre
            );
    }

    // V3
    function swapInputV3(
        address _router,
        bytes memory _path,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinArr,
        address _inputAddre,
        address _outAddre
    ) internal returns (uint256) {
        uint256 amountsv3;
        if (_outAddre == address(0)) {
            amountsv3 = swapExactInputV3(
                _router,
                _path,
                address(this),
                _amountIn,
                _amountOutMinArr,
                _inputAddre
            );
            IWETH9(getWeth(_router)).withdraw(amountsv3);
            TransferHelper.safeTransferETH(_recipient, amountsv3);
        } else {
            amountsv3 = swapExactInputV3(
                _router,
                _path,
                _recipient,
                _amountIn,
                _amountOutMinArr,
                _inputAddre
            );
        }
        return amountsv3;
    }

    function swapExactInputV3(
        address _router,
        bytes memory _path,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinArr,
        address _inputAddre
    ) internal returns (uint amount) {
        if (_inputAddre == address(0)) {
            amount = IV3SwapRouter(_router).exactInput{value: _amountIn}(
                IV3SwapRouter.ExactInputParams(
                    _path,
                    _recipient,
                    _amountIn,
                    _amountOutMinArr
                )
            );
        } else {
            TransferHelper.safeApprove(_inputAddre, _router, _amountIn);

            amount = IV3SwapRouter(_router).exactInput(
                IV3SwapRouter.ExactInputParams(
                    _path,
                    _recipient,
                    _amountIn,
                    _amountOutMinArr
                )
            );
        }
    }

    function getWeth(address _routerArr) public pure returns (address WETH) {
        WETH = IV3SwapRouter(_routerArr).WETH9();
    }

    receive() external payable {}
}
