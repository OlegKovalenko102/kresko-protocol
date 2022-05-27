/* Autogenerated file. Do not edit manually. */
// @ts-nocheck
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type { IKresko, IKreskoInterface } from "../IKresko";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "address",
        name: "_kreskoAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_mintedKreskoAssetIndex",
        type: "uint256",
      },
    ],
    name: "burnKreskoAsset",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "address",
        name: "_repayKreskoAsset",
        type: "address",
      },
      {
        internalType: "address",
        name: "_collateralAssetToSeize",
        type: "address",
      },
    ],
    name: "calculateMaxLiquidatableValueForAssets",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "collateralAssets",
    outputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "uint256",
                name: "rawValue",
                type: "uint256",
              },
            ],
            internalType: "struct FixedPoint.Unsigned",
            name: "factor",
            type: "tuple",
          },
          {
            internalType: "contract AggregatorV2V3Interface",
            name: "oracle",
            type: "address",
          },
          {
            internalType: "address",
            name: "underlyingRebasingToken",
            type: "address",
          },
          {
            internalType: "uint8",
            name: "decimals",
            type: "uint8",
          },
          {
            internalType: "bool",
            name: "exists",
            type: "bool",
          },
        ],
        internalType: "struct IKresko.CollateralAsset",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "collateralDeposits",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "collateralExists",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "address",
        name: "_collateralAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "depositCollateral",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "address",
        name: "_collateralAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_rebasingAmount",
        type: "uint256",
      },
    ],
    name: "depositRebasingCollateral",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "getAccountCollateralValue",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "getAccountKrAssetValue",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "getAccountMinimumCollateralValue",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_collateralAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "_ignoreCollateralFactor",
        type: "bool",
      },
    ],
    name: "getCollateralValueAndOraclePrice",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "getDepositedCollateralAssetIndex",
    outputs: [
      {
        internalType: "uint256",
        name: "i",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
    ],
    name: "getDepositedCollateralAssets",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_kreskoAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "_ignoreKfactor",
        type: "bool",
      },
    ],
    name: "getKrAssetValue",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_krAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "getMinimumCollateralValue",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
    ],
    name: "getMintedKreskoAssets",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "getMintedKreskoAssetsIndex",
    outputs: [
      {
        internalType: "uint256",
        name: "i",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "krAssetExists",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "kreskoAssetDebt",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "kreskoAssets",
    outputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "uint256",
                name: "rawValue",
                type: "uint256",
              },
            ],
            internalType: "struct FixedPoint.Unsigned",
            name: "kFactor",
            type: "tuple",
          },
          {
            internalType: "contract AggregatorV2V3Interface",
            name: "oracle",
            type: "address",
          },
          {
            internalType: "bool",
            name: "exists",
            type: "bool",
          },
          {
            internalType: "bool",
            name: "mintable",
            type: "bool",
          },
        ],
        internalType: "struct IKresko.KrAsset",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "minimumCollateralizationRatio",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "rawValue",
            type: "uint256",
          },
        ],
        internalType: "struct FixedPoint.Unsigned",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "address",
        name: "_kreskoAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "mintKreskoAsset",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "address",
        name: "_collateralAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_depositedCollateralAssetIndex",
        type: "uint256",
      },
    ],
    name: "withdrawCollateral",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "address",
        name: "_collateralAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_depositedCollateralAssetIndex",
        type: "uint256",
      },
    ],
    name: "withdrawRebasingCollateral",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class IKresko__factory {
  static readonly abi = _abi;
  static createInterface(): IKreskoInterface {
    return new utils.Interface(_abi) as IKreskoInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IKresko {
    return new Contract(address, _abi, signerOrProvider) as IKresko;
  }
}
