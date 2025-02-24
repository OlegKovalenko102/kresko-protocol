import { MockContract, smock } from "@defi-wonderland/smock";
import hre, { ethers } from "hardhat";
import { FluxPriceFeed__factory } from "types/typechain";
import { getUsers } from "@utils/general";
import { defaultCloseFee, defaultOracleDecimals, defaultOraclePrice } from "../mocks";
import { toBig } from "@kreskolabs/lib";
import { calcDebtIndex, getBlockTimestamp, fromScaledAmount } from "./calculations";
/* -------------------------------------------------------------------------- */
/*                                  GENERAL                                   */
/* -------------------------------------------------------------------------- */

export const getMockOracleFor = async (assetName = "Asset", price = defaultOraclePrice, marketOpen = true) => {
    const FakeFeed = await smock.fake<FluxPriceFeed>("FluxPriceFeed");
    const users = await getUsers();

    const MockFeed = await (
        await smock.mock<FluxPriceFeed__factory>("FluxPriceFeed")
    ).deploy(users.deployer.address, defaultOracleDecimals, assetName);

    MockFeed.latestAnswer.returns(hre.toBig(price, 8));
    MockFeed.latestMarketOpen.returns(marketOpen);
    FakeFeed.latestAnswer.returns(hre.toBig(price, 8));
    FakeFeed.latestMarketOpen.returns(marketOpen);
    return [MockFeed, FakeFeed] as const;
};

export const setPrice = (oracles: any, price: number) => {
    oracles.priceFeed.latestAnswer.returns(hre.toBig(price, 8));
    oracles.mockFeed.latestAnswer.returns(hre.toBig(price, 8));
};

export const setMarketOpen = (oracle: MockContract<FluxPriceFeed>, marketOpen: boolean) => {
    oracle.latestMarketOpen.returns(marketOpen);
};

export const getHealthFactor = async (user: SignerWithAddress) => {
    const accountKrAssetValue = hre.fromBig((await hre.Diamond.getAccountKrAssetValue(user.address)).rawValue, 8);
    const accountCollateral = hre.fromBig((await hre.Diamond.getAccountCollateralValue(user.address)).rawValue, 8);

    return accountCollateral / accountKrAssetValue;
};

export const leverageKrAsset = async (
    user: SignerWithAddress,
    krAsset: any,
    collateralToUse: any,
    amount: BigNumber,
) => {
    await collateralToUse.contract.connect(user).approve(hre.Diamond.address, hre.ethers.constants.MaxUint256);
    await krAsset.contract.connect(user).approve(hre.Diamond.address, hre.ethers.constants.MaxUint256);

    const krAssetValue = hre.fromBig((await hre.Diamond.getKrAssetValue(krAsset.address, amount, false)).rawValue, 8);
    const MCR = hre.fromBig((await hre.Diamond.minimumCollateralizationRatio()).rawValue);
    const collateralValueRequired = krAssetValue * MCR;
    const [collateralValue] = await hre.Diamond.getCollateralValueAndOraclePrice(
        collateralToUse.address,
        hre.toBig(1),
        false,
    );

    const price = hre.fromBig(collateralValue.rawValue, 8);
    const collateralAmount = collateralValueRequired / price;

    await collateralToUse.mocks.contract.setVariable("_balances", {
        [user.address]: hre.toBig(collateralAmount),
    });
    if (!(await hre.Diamond.collateralAsset(collateralToUse.address)).exists) {
        await hre.Diamond.connect(hre.users.operator).addCollateralAsset(
            collateralToUse.address,
            collateralToUse.anchor ? collateralToUse.anchor.address : ethers.constants.AddressZero,
            hre.toBig(1),
            collateralToUse.priceFeed.address,
            collateralToUse.priceFeed.address,
        );
    }
    await hre.Diamond.connect(user).depositCollateral(
        user.address,
        collateralToUse.address,
        hre.toBig(collateralAmount),
    );
    if (!(await hre.Diamond.kreskoAsset(krAsset.address)).exists) {
        await hre.Diamond.connect(hre.users.operator).addKreskoAsset(
            krAsset.address,
            krAsset.anchor.address,
            toBig(1),
            krAsset.priceFeed.address,
            krAsset.priceFeed.address,
            hre.toBig(1_000_000),
            defaultCloseFee,
            0,
        );
    }
    await hre.Diamond.connect(user).mintKreskoAsset(user.address, krAsset.address, amount);

    if (!(await hre.Diamond.collateralAsset(krAsset.address)).exists) {
        await hre.Diamond.connect(hre.users.operator).addCollateralAsset(
            krAsset.address,
            krAsset.anchor.address,
            toBig(1),
            krAsset.priceFeed.address,
            krAsset.priceFeed.address,
        );
    }
    await hre.Diamond.connect(user).depositCollateral(user.address, krAsset.address, amount);

    // Deposit krAsset and withdraw other collateral to bare minimum of within healthy range
    const accountMinCollateralRequired = await hre.Diamond.getAccountMinimumCollateralValueAtRatio(user.address, {
        rawValue: hre.toBig(1.5),
    });
    const accountCollateral = await hre.Diamond.getAccountCollateralValue(user.address);

    const withdrawAmount =
        hre.fromBig(accountCollateral.rawValue.sub(accountMinCollateralRequired.rawValue), 8) / price - 0.1;
    const amountToWithdraw = hre.toBig(withdrawAmount).rayDiv(await hre.Diamond.getDebtIndexForAsset(krAsset.address));

    if (amountToWithdraw.gt(0)) {
        await hre.Diamond.connect(user).withdrawCollateral(
            user.address,
            collateralToUse.address,
            amountToWithdraw,
            await hre.Diamond.getDepositedCollateralAssetIndex(user.address, collateralToUse.address),
        );

        // "burn" collateral not needed
        await collateralToUse.contract.connect(user).transfer(hre.ethers.constants.AddressZero, amountToWithdraw);
    }
};
