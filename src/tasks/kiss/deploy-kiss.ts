import type { KISS, KISSConverter, KreskoAssetAnchor, MockERC20 } from "types";
import type { TaskArguments } from "hardhat/types";
import { deployWithSignatures } from "@utils/deployment";
import { defaultSupplyLimit } from "@utils/test/mocks";
import { task, types } from "hardhat/config";
import { wrapperPrefix } from "src/config/minter";
import { Role } from "@utils/test/roles";

task("deploy-kiss")
    .addOptionalParam("wait", "wait confirmations", 1, types.int)
    .addOptionalParam("amount", "Amount to mint to deployer", 1_000_000_000, types.float)
    .setAction(async function (taskArgs: TaskArguments, hre) {
        const users = hre.users;
        const deploy = deployWithSignatures(hre);

        const { amount, decimals } = taskArgs;
        const [KISSContract] = await deploy<KISS>("KISS", {
            from: users.deployer.address,
            contract: "KISS",
            log: true,
            args: ["KISS", "KISS", decimals, hre.Diamond.address],
        });

        const DAI = await hre.ethers.getContract<MockERC20>("DAI");

        const underlyings = [DAI.address];
        const [KISSConverter] = await deploy<KISSConverter>("KISSConverter", {
            from: users.deployer.address,
            log: true,
            args: [KISSContract.address, underlyings],
        });

        await KISSContract.grantRole(await KISSContract.OPERATOR_ROLE(), KISSConverter.address);

        await DAI.approve(KISSConverter.address, hre.ethers.constants.MaxUint256);
        await KISSContract.approve(KISSConverter.address, hre.ethers.constants.MaxUint256);

        await KISSConverter.issue(users.deployer.address, DAI.address, hre.toBig(amount, decimals));
        console.log("Issued", amount, "of KISS to", users.deployer.address);

        const kreskoAssetAnchorInitArgs = [
            KISSContract.address,
            wrapperPrefix + "KISS",
            wrapperPrefix + "KISS",
            users.deployer.address,
        ];
        const [KISSUselessAnchor] = await deploy<KreskoAssetAnchor>(wrapperPrefix + "KISS", {
            from: users.deployer.address,
            log: true,
            contract: "KreskoAssetAnchor",
            args: [KISSContract.address],
            proxy: {
                owner: users.deployer.address,
                proxyContract: "OptimizedTransparentProxy",
                execute: {
                    methodName: "initialize",
                    args: kreskoAssetAnchorInitArgs,
                },
            },
        });
        const asset: KrAsset = {
            address: KISSContract.address,
            contract: KISSContract as unknown as KreskoAsset,
            anchor: KISSUselessAnchor,
            deployArgs: {
                name: "KISS",
                price: 1,
                mintable: false,
                factor: 1,
                supplyLimit: defaultSupplyLimit,
                closeFee: 0,
            },
            kresko: async () => await hre.Diamond.kreskoAsset(KISSContract.address),
            getPrice: async () => hre.toBig(1, 8),
            priceAggregator: undefined,
            priceFeed: undefined,
        };
        const hasRole = await KISSContract.hasRole(Role.OPERATOR, hre.Diamond.address);
        const kresko = await KISSContract.kresko();
        if (!hasRole) {
            throw new Error(`NO ROLE ${hre.Diamond.address} ${kresko}`);
        }
        const found = hre.krAssets.findIndex(c => c.address === asset.address);
        if (found === -1) {
            hre.krAssets.push(asset);
            hre.allAssets.push(asset);
        } else {
            hre.krAssets = hre.krAssets.map(c => (c.address === c.address ? asset : c));
            hre.allAssets = hre.allAssets.map(c => (c.address === asset.address && c.collateral ? asset : c));
        }
        return {
            contract: KISSContract,
            anchor: KISSUselessAnchor,
        };
    });
