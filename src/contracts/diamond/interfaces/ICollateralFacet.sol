// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../libraries/FP.sol" as FixedPoint;

interface ICollateralFacet {
    function collateralExists(address _collateralAsset) external view returns (bool);

    function getAccountCollateralValue(address _account) external view returns (FixedPoint.Unsigned memory);

    function getAccountMinimumCollateralValue(address _account) external view returns (FixedPoint.Unsigned memory);

    function getCollateralValueAndOraclePrice(
        address _collateralAsset,
        uint256 _amount,
        bool _ignoreCollateralFactor
    ) external view returns (FixedPoint.Unsigned memory, FixedPoint.Unsigned memory);

    function getDepositedCollateralAssetIndex(address _account, address _collateralAsset)
        external
        view
        returns (uint256 i);

    function getDepositedCollateralAssets(address _account) external view returns (address[] memory);
}
