{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Cardano.CLI.Legacy.Run.Transaction
  ( runLegacyTransactionCmds
  ) where

import           Cardano.Api

import qualified Cardano.CLI.EraBased.Commands.Transaction as Cmd
import           Cardano.CLI.EraBased.Run.Transaction
import           Cardano.CLI.Legacy.Commands.Transaction
import           Cardano.CLI.Types.Common
import           Cardano.CLI.Types.Errors.TxCmdError
import           Cardano.CLI.Types.Governance

import           Control.Monad.Trans.Except


runLegacyTransactionCmds :: LegacyTransactionCmds -> ExceptT TxCmdError IO ()
runLegacyTransactionCmds = \case
  TransactionBuildCmd mNodeSocketPath era consensusModeParams nid mScriptValidity mOverrideWits txins readOnlyRefIns
            reqSigners txinsc mReturnColl mTotCollateral txouts changeAddr mValue mLowBound
            mUpperBound certs wdrls metadataSchema scriptFiles metadataFiles mUpProp mconwayVote
            mNewConstitution outputOptions -> do
      runLegacyTransactionBuildCmd mNodeSocketPath era consensusModeParams nid mScriptValidity mOverrideWits txins readOnlyRefIns
            reqSigners txinsc mReturnColl mTotCollateral txouts changeAddr mValue mLowBound
            mUpperBound certs wdrls metadataSchema scriptFiles metadataFiles mUpProp mconwayVote
            mNewConstitution outputOptions
  TransactionBuildRawCmd era mScriptValidity txins readOnlyRefIns txinsc mReturnColl
               mTotColl reqSigners txouts mValue mLowBound mUpperBound fee certs wdrls
               metadataSchema scriptFiles metadataFiles mProtocolParamsFile mUpProp out -> do
      runLegacyTransactionBuildRawCmd era mScriptValidity txins readOnlyRefIns txinsc mReturnColl
               mTotColl reqSigners txouts mValue mLowBound mUpperBound fee certs wdrls
               metadataSchema scriptFiles metadataFiles mProtocolParamsFile mUpProp out
  TransactionSignCmd txinfile skfiles network txoutfile ->
      runLegacyTransactionSignCmd txinfile skfiles network txoutfile
  TransactionSubmitCmd mNodeSocketPath anyConsensusModeParams network txFp ->
      runLegacyTransactionSubmitCmd mNodeSocketPath anyConsensusModeParams network txFp
  TransactionCalculateMinFeeCmd txbody nw pParamsFile nInputs nOutputs nShelleyKeyWitnesses nByronKeyWitnesses ->
      runLegacyTransactionCalculateMinFeeCmd txbody nw pParamsFile nInputs nOutputs nShelleyKeyWitnesses nByronKeyWitnesses
  TransactionCalculateMinValueCmd era pParamsFile txOuts' ->
      runLegacyTransactionCalculateMinValueCmd era pParamsFile txOuts'
  TransactionHashScriptDataCmd scriptDataOrFile ->
      runLegacyTransactionHashScriptDataCmd scriptDataOrFile
  TransactionTxIdCmd txinfile ->
      runLegacyTransactionTxIdCmd txinfile
  TransactionViewCmd yamlOrJson mOutFile txinfile ->
      runLegacyTransactionViewCmd yamlOrJson mOutFile txinfile
  TransactionPolicyIdCmd sFile ->
      runLegacyTransactionPolicyIdCmd sFile
  TransactionWitnessCmd txBodyfile witSignData mbNw outFile ->
      runLegacyTransactionWitnessCmd txBodyfile witSignData mbNw outFile
  TransactionSignWitnessCmd txBodyFile witnessFile outFile ->
      runLegacyTransactionSignWitnessCmd txBodyFile witnessFile outFile

-- ----------------------------------------------------------------------------
-- Building transactions
--

runLegacyTransactionBuildCmd :: ()
  => SocketPath
  -> AnyCardanoEra
  -> AnyConsensusModeParams
  -> NetworkId
  -> Maybe ScriptValidity
  -> Maybe Word -- ^ Override the required number of tx witnesses
  -> [(TxIn, Maybe (ScriptWitnessFiles WitCtxTxIn))] -- ^ Transaction inputs with optional spending scripts
  -> [TxIn] -- ^ Read only reference inputs
  -> [RequiredSigner] -- ^ Required signers
  -> [TxIn] -- ^ Transaction inputs for collateral, only key witnesses, no scripts.
  -> Maybe TxOutAnyEra -- ^ Return collateral
  -> Maybe Lovelace -- ^ Total collateral
  -> [TxOutAnyEra]
  -> TxOutChangeAddress
  -> Maybe (Value, [ScriptWitnessFiles WitCtxMint])
  -> Maybe SlotNo -- ^ Validity lower bound
  -> Maybe SlotNo -- ^ Validity upper bound
  -> [(CertificateFile, Maybe (ScriptWitnessFiles WitCtxStake))]
  -> [(StakeAddress, Lovelace, Maybe (ScriptWitnessFiles WitCtxStake))] -- ^ Withdrawals with potential script witness
  -> TxMetadataJsonSchema
  -> [ScriptFile]
  -> [MetadataFile]
  -> Maybe UpdateProposalFile
  -> [VoteFile In]
  -> [ProposalFile In]
  -> TxBuildOutputOptions
  -> ExceptT TxCmdError IO ()
runLegacyTransactionBuildCmd
    socketPath (AnyCardanoEra era)
    consensusModeParams nid mScriptValidity mOverrideWits txins readOnlyRefIns
    reqSigners txinsc mReturnColl mTotCollateral txouts changeAddr mValue mLowBound
    mUpperBound certs wdrls metadataSchema scriptFiles metadataFiles mUpProp voteFiles
    proposalFiles outputOptions =
  runTransactionBuildCmd
    ( Cmd.TransactionBuildCmdArgs era socketPath
        consensusModeParams nid mScriptValidity mOverrideWits txins readOnlyRefIns
        reqSigners txinsc mReturnColl mTotCollateral txouts changeAddr mValue mLowBound
        mUpperBound certs wdrls metadataSchema scriptFiles metadataFiles mUpProp voteFiles
        proposalFiles outputOptions
    )

runLegacyTransactionBuildRawCmd :: ()
  => AnyCardanoEra
  -> Maybe ScriptValidity
  -> [(TxIn, Maybe (ScriptWitnessFiles WitCtxTxIn))]
  -> [TxIn] -- ^ Read only reference inputs
  -> [TxIn] -- ^ Transaction inputs for collateral, only key witnesses, no scripts.
  -> Maybe TxOutAnyEra
  -> Maybe Lovelace -- ^ Total collateral
  -> [RequiredSigner]
  -> [TxOutAnyEra]
  -> Maybe (Value, [ScriptWitnessFiles WitCtxMint]) -- ^ Multi-Asset value with script witness
  -> Maybe SlotNo -- ^ Validity lower bound
  -> Maybe SlotNo -- ^ Validity upper bound
  -> Maybe Lovelace -- ^ Tx fee
  -> [(CertificateFile, Maybe (ScriptWitnessFiles WitCtxStake))]
  -> [(StakeAddress, Lovelace, Maybe (ScriptWitnessFiles WitCtxStake))]
  -> TxMetadataJsonSchema
  -> [ScriptFile]
  -> [MetadataFile]
  -> Maybe ProtocolParamsFile
  -> Maybe UpdateProposalFile
  -> TxBodyFile Out
  -> ExceptT TxCmdError IO ()
runLegacyTransactionBuildRawCmd
    (AnyCardanoEra era) mScriptValidity txins readOnlyRefIns txinsc mReturnColl
    mTotColl reqSigners txouts mValue mLowBound mUpperBound fee certs wdrls
    metadataSchema scriptFiles metadataFiles mProtocolParamsFile mUpProp outFile =
  runTransactionBuildRawCmd
    ( Cmd.TransactionBuildRawCmdArgs
        era mScriptValidity txins readOnlyRefIns txinsc mReturnColl
        mTotColl reqSigners txouts mValue mLowBound mUpperBound fee certs wdrls
        metadataSchema scriptFiles metadataFiles mProtocolParamsFile mUpProp [] []
        outFile
    )

runLegacyTransactionSignCmd :: InputTxBodyOrTxFile
          -> [WitnessSigningData]
          -> Maybe NetworkId
          -> TxFile Out
          -> ExceptT TxCmdError IO ()
runLegacyTransactionSignCmd
    txOrTxBody
    witSigningData
    mnw
    outTxFile =
  runTransactionSignCmd
    ( Cmd.TransactionSignCmdArgs
       txOrTxBody
       witSigningData
       mnw
       outTxFile
    )

runLegacyTransactionSubmitCmd :: ()
  => SocketPath
  -> AnyConsensusModeParams
  -> NetworkId
  -> FilePath
  -> ExceptT TxCmdError IO ()
runLegacyTransactionSubmitCmd
    socketPath
    anyConsensusModeParams
    network
    txFilePath =
  runTransactionSubmitCmd
    ( Cmd.TransactionSubmitCmdArgs
        socketPath
        anyConsensusModeParams
        network
        txFilePath
     )

runLegacyTransactionCalculateMinFeeCmd :: ()
  => TxBodyFile In
  -> NetworkId
  -> ProtocolParamsFile
  -> TxInCount
  -> TxOutCount
  -> TxShelleyWitnessCount
  -> TxByronWitnessCount
  -> ExceptT TxCmdError IO ()
runLegacyTransactionCalculateMinFeeCmd
    txbodyFile
    nw
    pParamsFile
    txInCount
    txOutCount
    txShelleyWitnessCount
    txByronWitnessCount =
  runTransactionCalculateMinFeeCmd
    ( Cmd.TransactionCalculateMinFeeCmdArgs
        txbodyFile
        nw
        pParamsFile
        txInCount
        txOutCount
        txShelleyWitnessCount
        txByronWitnessCount
    )

runLegacyTransactionCalculateMinValueCmd :: ()
  => AnyCardanoEra
  -> ProtocolParamsFile
  -> TxOutAnyEra
  -> ExceptT TxCmdError IO ()
runLegacyTransactionCalculateMinValueCmd
    (AnyCardanoEra era)
    pParamsFile
    txOut =
  runTransactionCalculateMinValueCmd
    ( Cmd.TransactionCalculateMinValueCmdArgs
        era
        pParamsFile
        txOut
    )

runLegacyTransactionPolicyIdCmd ::  ScriptFile -> ExceptT TxCmdError IO ()
runLegacyTransactionPolicyIdCmd scriptFile =
  runTransactionPolicyIdCmd
    ( Cmd.TransactionPolicyIdCmdArgs
        scriptFile
    )

runLegacyTransactionHashScriptDataCmd :: ScriptDataOrFile -> ExceptT TxCmdError IO ()
runLegacyTransactionHashScriptDataCmd scriptDataOrFile =
  runTransactionHashScriptDataCmd
    ( Cmd.TransactionHashScriptDataCmdArgs
        scriptDataOrFile
    )

runLegacyTransactionTxIdCmd :: InputTxBodyOrTxFile -> ExceptT TxCmdError IO ()
runLegacyTransactionTxIdCmd txfile =
  runTransactionTxIdCmd
    ( Cmd.TransactionTxIdCmdArgs
        txfile
    )

runLegacyTransactionViewCmd :: TxViewOutputFormat -> Maybe (File () Out) -> InputTxBodyOrTxFile -> ExceptT TxCmdError IO ()
runLegacyTransactionViewCmd
    yamlOrJson
    mOutFile
    inputTxBodyOrTxFile =
  runTransactionViewCmd
    ( Cmd.TransactionViewCmdArgs
        yamlOrJson
        mOutFile
        inputTxBodyOrTxFile
    )

runLegacyTransactionWitnessCmd :: ()
  => TxBodyFile In
  -> WitnessSigningData
  -> Maybe NetworkId
  -> File () Out
  -> ExceptT TxCmdError IO ()
runLegacyTransactionWitnessCmd
    txbodyFile
    witSignData
    mbNw
    outFile =
  runTransactionWitnessCmd
    ( Cmd.TransactionWitnessCmdArgs
        txbodyFile
        witSignData
        mbNw
        outFile
     )

runLegacyTransactionSignWitnessCmd :: ()
  => TxBodyFile In
  -> [WitnessFile]
  -> File () Out
  -> ExceptT TxCmdError IO ()
runLegacyTransactionSignWitnessCmd
    txbodyFile
    witnessFiles
    outFile =
  runTransactionSignWitnessCmd
    ( Cmd.TransactionSignWitnessCmdArgs
        txbodyFile
        witnessFiles
        outFile
    )
