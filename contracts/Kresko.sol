// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./KreskoAsset.sol";

contract Kresko is Ownable {
    /**
     * Whitelist of assets that can be used as collateral
     * with their respective collateral factor and oracle address
     */
    struct CollateralAsset {
        uint256 factor;
        address oracle;
        bool exists;
    }

    /**
     * Whitelist of kresko assets with their respective name,
     * deployed address, k factor, and oracle address
     */
    struct KAsset {
        uint256 kFactor;
        address oracle;
        bool exists;
    }

    mapping(address => CollateralAsset) public collateralAssets;
    mapping(address => KAsset) public kreskoAssets;
    mapping(string => bool) public kreskoAssetSymbols; // Prevents duplicate KreskoAsset symbols

    // Collateral asset events
    event AddCollateralAsset(address assetAddress, uint256 factor, address oracle);
    event UpdateCollateralAssetFactor(address assetAddress, uint256 factor);
    event UpdateCollateralAssetOracle(address assetAddress, address oracle);
    // Kresko asset events
    event AddKreskoAsset(string name, string symbol, address assetAddress, uint256 kFactor, address oracle);
    event UpdateKreskoAssetKFactor(address assetAddress, uint256 kFactor);
    event UpdateKreskoAssetOracle(address assetAddress, address oracle);

    modifier collateralAssetExists(address assetAddress) {
        require(collateralAssets[assetAddress].exists, "ASSET_NOT_VALID");
        _;
    }

    modifier collateralAssetDoesNotExist(address assetAddress) {
        require(!collateralAssets[assetAddress].exists, "ASSET_EXISTS");
        _;
    }

    modifier kreskoAssetExists(address assetAddress) {
        require(kreskoAssets[assetAddress].exists, "ASSET_NOT_VALID");
        _;
    }

    modifier kreskoAssetDoesNotExist(string calldata symbol) {
        require(!kreskoAssetSymbols[symbol], "SYMBOL_NOT_VALID");
        _;
    }

    modifier nonNullString(string calldata str) {
        require(keccak256(abi.encodePacked((str))) != keccak256(abi.encodePacked((""))), "NULL_STRING");
        _;
    }

    constructor() {
        // Intentionally left blank
    }

    /**
     * @dev Whitelists a collateral asset
     * @param assetAddress The on chain address of the collateral asset
     * @param factor The collateral factor of the collateral asset
     * @param oracle The oracle address for the collateral asset
     */
    function addCollateralAsset(
        address assetAddress,
        uint256 factor,
        address oracle
    )
        external
        onlyOwner
        collateralAssetDoesNotExist(assetAddress)
    {
        require(assetAddress != address(0), "ZERO_ADDRESS");
        require(factor != 0, "INVALID_FACTOR");
        require(oracle != address(0), "ZERO_ADDRESS");

        collateralAssets[assetAddress] = CollateralAsset({ factor: factor, oracle: oracle, exists: true });
        emit AddCollateralAsset(assetAddress, factor, oracle);
    }

    /**
     * @dev Updates the collateral factor of a previously whitelisted collateral asset
     * @param assetAddress The on chain address of the collateral asset
     * @param factor The new collateral factor of the collateral asset
     */
    function updateCollateralFactor(address assetAddress, uint256 factor)
        external
        onlyOwner
        collateralAssetExists(assetAddress)
    {
        require(factor != 0, "INVALID_FACTOR");

        collateralAssets[assetAddress].factor = factor;
        emit UpdateCollateralAssetFactor(assetAddress, factor);
    }

    /**
     * @dev Updates the oracle address of a previously whitelisted collateral asset
     * @param assetAddress The on chain address of the collateral asset
     * @param oracle The new oracle address for the collateral asset
     */
    function updateCollateralOracle(address assetAddress, address oracle)
        external
        onlyOwner
        collateralAssetExists(assetAddress)
    {
        require(oracle != address(0), "ZERO_ADDRESS");

        collateralAssets[assetAddress].oracle = oracle;
        emit UpdateCollateralAssetOracle(assetAddress, oracle);
    }

    /**
     * @dev Whitelists a kresko asset
     * @param name The name of the kresko asset
     * @param symbol The symbol of the kresko asset
     * @param kFactor The k factor of the kresko asset
     * @param oracle The oracle address for the kresko asset
     */
    function addKreskoAsset(
        string calldata name,
        string calldata symbol,
        uint256 kFactor,
        address oracle
    )
        external
        onlyOwner
        nonNullString(symbol)
        nonNullString(name)
        kreskoAssetDoesNotExist(symbol)
    {
        require(kFactor != 0, "INVALID_FACTOR");
        require(oracle != address(0), "ZERO_ADDRESS");

        // Store symbol to prevent duplicate KreskoAsset symbols
        kreskoAssetSymbols[symbol] = true;

        // Deploy KreskoAsset contract and store its details
        KreskoAsset asset = new KreskoAsset(name, symbol);
        kreskoAssets[address(asset)] = KAsset({
            kFactor: kFactor,
            oracle: oracle,
            exists: true
        });
        emit AddKreskoAsset(name, symbol, address(asset), kFactor, oracle);
    }

    /**
     * @dev Updates the k factor of a previously whitelisted kresko asset
     * @param assetAddress The address of the kresko asset
     * @param kFactor The new k factor of the kresko asset
     */
    function updateKreskoAssetFactor(address assetAddress, uint256 kFactor)
        external
        onlyOwner
        kreskoAssetExists(assetAddress)
    {
        require(kFactor != 0, "INVALID_FACTOR");

        kreskoAssets[assetAddress].kFactor = kFactor;
        emit UpdateKreskoAssetKFactor(assetAddress, kFactor);
    }

    /**
     * @dev Updates the oracle address of a previously whitelisted kresko asset
     * @param assetAddress The address of the kresko asset
     * @param oracle The new oracle address for the kresko asset
     */
    function updateKreskoAssetOracle(address assetAddress, address oracle)
        external
        onlyOwner
        kreskoAssetExists(assetAddress)
    {
        require(oracle != address(0), "ZERO_ADDRESS");

        kreskoAssets[assetAddress].oracle = oracle;
        emit UpdateKreskoAssetOracle(assetAddress, oracle);
    }
}
