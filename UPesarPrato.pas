unit UPesarPrato;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, uDMCupomFiscal, StdCtrls, Mask, ToolEdit, CurrEdit,
  NxCollection, ExtCtrls, AdvPanel, SqlExpr, ACBrBase, ACBrBAL, ACBrDeviceSerial,
  jpeg;

type
  TfrmPesarPrato = class(TForm)
    Timer1: TTimer;
    pnlPrincipal: TAdvPanel;
    Label1: TLabel;
    Label2: TLabel;
    lblNumComanda: TLabel;
    Label4: TLabel;
    lblNomeProduto: TLabel;
    Panel1: TNxPanel;
    Label3: TLabel;
    cePeso: TCurrencyEdit;
    ceIDProduto: TCurrencyEdit;
    Label5: TLabel;
    cePrecoLivre: TCurrencyEdit;
    Label6: TLabel;
    cePrecoKg: TCurrencyEdit;
    ACBrBAL1: TACBrBAL;
    Image2: TImage;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure cePesoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure ACBrBAL1LePeso(Peso: Double; Resposta: String);
  private
    { Private declarations }
    fDmCupomFiscal: TDmCupomFiscal;
    vIdCupom: Integer;

    procedure prc_Produto_Padrao;
    function fnc_Gravar_Comanda: Integer;
    procedure prc_Inserir_Itens;
    procedure prc_Mover_Itens;
    procedure prc_Preco_Livre;
    procedure prc_Pesar;
    procedure prc_ImprimirComanda(ID_Cupom: Integer);
    procedure prc_Grava_Cupom;

    function fnc_NumComanda: Integer;

  public
    { Public declarations }
  end;

var
  frmPesarPrato: TfrmPesarPrato;

implementation

uses DB, uUtilPadrao, DmdDatabase, uCalculo_CupomFiscal, rsDBUtils,
  uComandaR;

{$R *.dfm}

procedure TfrmPesarPrato.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FreeAndNil(fDmCupomFiscal);
  Action := Cafree;
end;

procedure TfrmPesarPrato.prc_Produto_Padrao;
begin
  ceIDProduto.AsInteger := fDmCupomFiscal.cdsCupomParametrosPRODUTO_PADRAO.AsInteger;
  lblNomeProduto.Caption := ceIDProduto.Text + ' - ' + SQLLocate('PRODUTO','ID','NOME',fDmCupomFiscal.cdsCupomParametrosPRODUTO_PADRAO.AsString);
end;

procedure TfrmPesarPrato.FormShow(Sender: TObject);
begin
  fDmCupomFiscal := TDmCupomFiscal.Create(Self);
  oDBUtils.SetDataSourceProperties(Self, fDmCupomFiscal);
  prc_Produto_Padrao;
  cePeso.SetFocus;

  timer1.Interval := StrToInt(SQLLocate('CUPOMFISCAL_PARAMETROS','ID','BALANCA_TIMER','1'));
  Timer1.Enabled  := True;

  fDmCupomFiscal.prc_Abrir_Produto('ID',ceIDProduto.Text);
  cePrecoLivre.Value := fDmCupomFiscal.cdsProdutoPRECO_LIVRE.Value;
  cePrecoKg.Value    := fDmCupomFiscal.cdsProdutoPRECO_VENDA.Value;
end;

procedure TfrmPesarPrato.cePesoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = Vk_Return) and (cePeso.Value > 0) then
    vIdCupom := fnc_Gravar_Comanda;
end;

function TfrmPesarPrato.fnc_Gravar_Comanda: Integer;
var
  vNumComanda: Integer;
  Form: TForm;
  vSerieCupom: String;
begin
  Result := 0;
  try
    Form := TForm.Create(Application);
    try
      uUtilPadrao.prc_Form_Aguarde(Form);
      vSerieCupom := fDmCupomFiscal.lerIni('IMPRESSORA', 'Serie');
      fDmCupomFiscal.vClienteID := fDmCupomFiscal.cdsParametrosID_CLIENTE_CONSUMIDOR.AsInteger;
      fDmCupomFiscal.prcInserir(0,fDmCupomFiscal.vClienteID, vSerieCupom);
      Result := fDmCupomFiscal.cdsCupomFiscalID.AsInteger;
      vNumComanda := fDmCupomFiscal.fnc_IncrementaCartao(vTerminal);
      fDmCupomFiscal.cdsCupomFiscalNUM_CARTAO.AsInteger := vNumComanda;
      lblNumComanda.Caption := IntToStr(vNumComanda);
      fDmCupomFiscal.cdsCupomFiscalTIPO.AsString := 'COM';
      prc_Inserir_Itens;
      prc_Grava_Cupom;
    finally
      FreeAndNil(Form);
    end;
  except
  end;
  cePeso.Clear;
  cePeso.SetFocus;
end;

function TfrmPesarPrato.fnc_NumComanda: Integer;
var
  sds: TSQLDataSet;
begin
  sds := TSQLDataSet.Create(nil);
  try
    sds.SQLConnection := dmDatabase.scoDados;
    sds.NoMetadata    := True;
    sds.GetMetadata   := False;
    sds.CommandText   := 'select max(C.NUM_CARTAO) NUM_CARTAO from CUPOMFISCAL C where C.DTEMISSAO = :DTEMISSAO';
    sds.ParamByName('DTEMISSAO').AsDate := Date;
    sds.Open;
    Result := sds.FieldByName('NUM_CARTAO').AsInteger + 1;
  finally
    FreeAndNil(sds);
  end;
end;

procedure TfrmPesarPrato.prc_Inserir_Itens;
var
  vItemAux: Integer;
begin
  fDmCupomFiscal.prc_Abrir_Produto('ID',ceIDProduto.Text);
  if fDmCupomFiscal.cdsProduto.IsEmpty then
  begin
    MessageDlg('Produto n�o encontradao!', mtInformation, [mbOk], 0);
    cePeso.SetFocus;
    exit;
  end;

  fDmCupomFiscal.cdsCupom_Itens.Last;
  vItemAux := fDmCupomFiscal.cdsCupom_ItensItem.AsInteger;
  try
    fDmCupomFiscal.cdsCupom_Itens.Insert;
    fDmCupomFiscal.cdsCupom_ItensID.AsInteger         := fDmCupomFiscal.cdsCupomFiscalID.AsInteger;
    fDmCupomFiscal.cdsCupom_ItensITEM.AsInteger       := vItemAux + 1;
    fDmCupomFiscal.cdsCupom_ItensID_PRODUTO.AsInteger := ceIDProduto.AsInteger;
    fDmCupomFiscal.cdsCupom_ItensQTD.AsFloat          := cePeso.Value;
    fDmCupomFiscal.cdsCupom_ItensVLR_UNITARIO.AsFloat       := fDmCupomFiscal.cdsProdutoPRECO_VENDA.AsFloat;
    fDmCupomFiscal.cdsCupom_ItensVLR_UNIT_ORIGINAL.AsFloat  := fDmCupomFiscal.cdsProdutoPRECO_VENDA.AsFloat;
    fDmCupomFiscal.cdsCupom_ItensVLR_DESCONTO.AsFloat := 0;
    fDmCupomFiscal.cdsCupom_ItensVLR_TOTAL.AsFloat := StrToFloat(FormatFloat('0.00',fDmCupomFiscal.cdsProdutoPRECO_VENDA.AsFloat * cePeso.Value));
    prc_Preco_Livre;
    prc_Mover_Itens;

    //NFCe
    if fDmCupomFiscal.cdsParametrosUSA_NFCE.AsString <> 'S' then
    begin
      fDmCupomFiscal.cdsCupom_ItensBASE_ICMS.AsFloat := 0;
      fDmCupomFiscal.cdsCupom_ItensVLR_ICMS.AsFloat := 0;
      if StrToFloat(FormatFloat('0.00', fDmCupomFiscal.cdsCupom_ItensPERC_ICMS.AsFloat)) > 0 then
      begin
        fDmCupomFiscal.cdsCupom_ItensBASE_ICMS.AsFloat := fDmCupomFiscal.cdsCupom_ItensVLR_TOTAL.AsFloat;
        if StrToFloat(FormatFloat('0.0000', fDmCupomFiscal.cdsCupom_ItensPERC_TRIBICMS.AsFloat)) > 0 then
          fDmCupomFiscal.cdsCupom_ItensBASE_ICMS.AsFloat := StrToFloat(FormatFloat('0.00', (fDmCupomFiscal.cdsCupom_ItensBASE_ICMS.AsFloat * fDmCupomFiscal.cdsCupom_ItensPERC_TRIBICMS.AsFloat / 100)));
        fDmCupomFiscal.cdsCupom_ItensVLR_ICMS.AsFloat := StrToFloat(FormatFloat('0.00', fDmCupomFiscal.cdsCupom_ItensBASE_ICMS.AsFloat * fDmCupomFiscal.cdsCupom_ItensPERC_ICMS.AsFloat / 100));
      end;
      fDmCupomFiscal.cdsCupom_ItensID_CFOP.AsInteger := 0;
    end;
    fDmCupomFiscal.cdsCupom_ItensREFERENCIA.AsString  := fDmCupomFiscal.cdsProdutoREFERENCIA.AsString;
    fDmCupomFiscal.cdsCupom_ItensORIGEM_PROD.AsString := fDmCupomFiscal.cdsProdutoORIGEM_PROD.AsString;
    fDmCupomFiscal.cdsCupom_ItensID_NCM.AsString      := fDmCupomFiscal.cdsProdutoID_NCM.AsString;
    fDmCupomFiscal.cdsCupom_ItensPRECO_CUSTO.AsFloat  := fDmCupomFiscal.cdsProdutoPRECO_CUSTO.AsFloat;
    fDmCupomFiscal.cdsCupom_ItensPRECO_CUSTO_TOTAL.AsFloat  := fDmCupomFiscal.cdsProdutoPRECO_CUSTO_TOTAL.AsFloat;

    fDmCupomFiscal.cdsCupom_ItensID_MOVESTOQUE.AsInteger := 0;
    fDmCupomFiscal.cdsCupom_ItensUNIDADE.AsString := fDmCupomFiscal.cdsProdutoUnidade.AsString;
    fDmCupomFiscal.cdsCupom_ItensNOMEPRODUTO.AsString := fDmCupomFiscal.cdsProdutoNome.AsString;
    fDmCupomFiscal.cdsCupom_ItensCANCELADO.AsString := 'N';
    fDmCupomFiscal.cdsCupom_ItensNOME_PRODUTO.AsString := fDmCupomFiscal.cdsProdutoNome.AsString;
    fDmCupomFiscal.prc_Busca_IBPT;

    if fDmCupomFiscal.cdsParametrosUSA_NFCE.AsString = 'S' then
    begin
      if fDmCupomFiscal.vID_CFOP > 0 then
      begin
        fDmCupomFiscal.cdsCupom_ItensID_CFOP.AsInteger := fDmCupomFiscal.vID_CFOP;
        if fDmCupomFiscal.vID_Variacao > 0 then
          fDmCupomFiscal.cdsCupom_ItensID_VARIACAO.AsInteger := fDmCupomFiscal.vID_Variacao;
      end;
      if fDmCupomFiscal.vID_Pis > 0 then
        fDmCupomFiscal.cdsCupom_ItensID_PIS.AsInteger := fDmCupomFiscal.vID_Pis;
      if fDmCupomFiscal.vID_Cofins > 0 then
        fDmCupomFiscal.cdsCupom_ItensID_COFINS.AsInteger := fDmCupomFiscal.vID_Cofins;
      if fDmCupomFiscal.vID_CSTICMS > 0 then
        fDmCupomFiscal.cdsCupom_ItensID_CSTICMS.AsInteger := fDmCupomFiscal.vID_CSTICMS;
      fDmCupomFiscal.cdsCupom_ItensTIPO_PIS.AsString := fDmCupomFiscal.vTipo_Pis;
      fDmCupomFiscal.cdsCupom_ItensTIPO_COFINS.AsString := fDmCupomFiscal.vTipo_Cofins;
      fDmCupomFiscal.cdsCupom_ItensPERC_PIS.AsFloat := fDmCupomFiscal.vPerc_Pis;
      fDmCupomFiscal.cdsCupom_ItensPERC_COFINS.AsFloat := fDmCupomFiscal.vPerc_Cofins;
      fDmCupomFiscal.cdsCupom_ItensPERC_TRIBICMS.AsFloat := fDmCupomFiscal.vPerc_TribICMS;
      if StrToFloat(FormatFloat('0.0000',fDmCupomFiscal.cdsProdutoVLR_ICMS.AsFloat)) > 0 then
        fDmCupomFiscal.cdsCupom_ItensALIQ_ICMS_ADREM.AsFloat := StrToFloat(FormatFloat('0.0000',fDmCupomFiscal.cdsProdutoVLR_ICMS.AsFloat))
      else
        fDmCupomFiscal.cdsCupom_ItensPERC_ICMS.AsFloat := fDmCupomFiscal.vPerc_ICMS;
      fDmCupomFiscal.cdsCupom_ItensPERC_IPI.AsFloat := 0;

      fDmCupomFiscal.prc_Busca_CodBenef;
      prc_Calculo_GeralItem(fDmCupomFiscal, fDmCupomFiscal.cdsCupom_ItensQTD.AsFloat, fDmCupomFiscal.cdsCupom_ItensVLR_UNIT_ORIGINAL.AsFloat, fDmCupomFiscal.cdsCupom_ItensVLR_DESCONTO.AsFloat, fDmCupomFiscal.cdsCupom_ItensPERC_DESCONTO.AsFloat, fDmCupomFiscal.cdsCupom_ItensVLR_TOTAL.AsFloat, fDmCupomFiscal.cdsCupom_ItensVLR_ACRESCIMO.AsFloat, 'S', 0);
    end;
    if (fDmCupomFiscal.cdsCupomFiscalTIPO.AsString = 'CFI') then
      prc_Calcular_Tributos_Transparencia(fDmCupomFiscal);
    fDmCupomFiscal.cdsCupom_ItensITEM_ORIGINAL.AsInteger := 0;

    fDmCupomFiscal.cdsCupom_Itens.Post;

  except
    on E: Exception do
    begin
      ShowMessage('N�o foi poss�vel incluir o item, ' + E.Message + '! Clique para continuar!');
      fDmCupomFiscal.cdsCupom_Itens.CancelUpdates;
    end;
  end;
end;

procedure TfrmPesarPrato.prc_Preco_Livre;
begin
  if (StrToFloat(FormatFloat('0.00', fDmCupomFiscal.cdsProdutoPRECO_LIVRE.AsFloat)) > 0)
    and (StrToFloat(FormatFloat('0.00',fDmCupomFiscal.cdsCupom_ItensVLR_TOTAL.AsFloat)) > StrToFloat(FormatFloat('0.00',fDmCupomFiscal.cdsProdutoPRECO_LIVRE.AsFloat))) then
  begin
    fDmCupomFiscal.cdsCupom_ItensVLR_UNITARIO.AsFloat      := StrToFloat(FormatFloat('0.00',fDmCupomFiscal.cdsProdutoPRECO_LIVRE.AsFloat));
    fDmCupomFiscal.cdsCupom_ItensVLR_UNIT_ORIGINAL.AsFloat := StrToFloat(FormatFloat('0.00',fDmCupomFiscal.cdsProdutoPRECO_LIVRE.AsFloat));
    fDmCupomFiscal.cdsCupom_ItensVLR_TOTAL.AsFloat         := StrToFloat(FormatFloat('0.00',fDmCupomFiscal.cdsProdutoPRECO_LIVRE.AsFloat));
    fDmCupomFiscal.cdsCupom_ItensQTD.AsInteger             := 1;
  end;
end;

procedure TfrmPesarPrato.prc_Mover_Itens;
begin
  fDmCupomFiscal.vID_NCM := fDmCupomFiscal.cdsProdutoID_NCM.AsInteger;
  if fDmCupomFiscal.vID_NCM > 0 then
    fDmCupomFiscal.cdsTab_NCM.Locate('ID', fDmCupomFiscal.vID_NCM, [loCaseInsensitive]);
  if fDmCupomFiscal.cdsProdutoID_CFOP_NFCE.AsInteger > 0 then
    fDmCupomFiscal.vID_CFOP := fDmCupomFiscal.cdsProdutoID_CFOP_NFCE.AsInteger
  else
  if (fDmCupomFiscal.cdsTab_NCMID_CFOP.AsInteger > 0) and (fDmCupomFiscal.cdsTab_NCMID.AsInteger = fDmCupomFiscal.cdsCupom_ItensID_NCM.AsInteger) then
    fDmCupomFiscal.vID_CFOP := fDmCupomFiscal.cdsTab_NCMID_CFOP.AsInteger
  else
  if fDmCupomFiscal.cdsFilialID_CFOP_NFCE_PADRAO.AsInteger > 0 then
    fDmCupomFiscal.vID_CFOP := fDmCupomFiscal.cdsFilialID_CFOP_NFCE_PADRAO.AsInteger;
  if fDmCupomFiscal.vID_CFOP > 0 then
    fDmCupomFiscal.cdsCFOP.Locate('ID', fDmCupomFiscal.vID_CFOP, [loCaseInsensitive]);
  fDmCupomFiscal.vID_Variacao := 0;
  if fDmCupomFiscal.vID_CFOP > 0 then
    fDmCupomFiscal.vID_Variacao := fDmCupomFiscal.fnc_Buscar_Regra_CFOP(fDmCupomFiscal.vID_CFOP);
  fDmCupomFiscal.prc_Mover_CST;
end;

procedure TfrmPesarPrato.Timer1Timer(Sender: TObject);
begin
  if vPeso = vPesoAtual then
  then
  begin
    Label3.Caption := 'RETIRE O PRATO DA BALAN�A!';
    Exit;
  end
  else
  begin
    prc_Pesar;
    Label3.Caption := 'COLOQUE O PRATO NA BALAN�A!';
  end;
end;

procedure TfrmPesarPrato.prc_Pesar;
var
  strPeso: string;
  TimeOut: Integer;
begin
  if acbrBal1.Ativo then
    ACBrBAL1.Desativar;

     // configura porta de comunica��o
  ACBrBAL1.Modelo := TACBrBALModelo(StrToInt(vModeloBalanca)); //urano us pop
  ACBrBAL1.Device.HandShake := TACBrHandShake(0);
  ACBrBAL1.Device.Parity := TACBrSerialParity(0);
  ACBrBAL1.Device.Stop   := TACBrSerialStop(0);
  ACBrBAL1.Device.Data   := StrToInt('8');
  ACBrBAL1.Device.Baud   := StrToINt(vVelBalanca);
  ACBrBAL1.Device.Porta  := vPortaBalanca;

     // Conecta com a balan�a
  ACBrBAL1.Ativar;
  TimeOut := 2000;
  ACBrBAL1.LePeso(TimeOut);
end;

procedure TfrmPesarPrato.ACBrBAL1LePeso(Peso: Double; Resposta: String);
var
  Valid: Integer;
  vTecla: Word;
begin
  if StrToFloat(FormatFloat('0.000',Peso)) > 0.006 then
  begin
    Timer1.Enabled := False;
    cePeso.Value   := Peso;
    vTecla         := vk_Return;
    cePesoKeyDown(cePeso,vTecla,[ssShift]);
    prc_ImprimirComanda(vIdCupom);
    Timer1.Enabled := True;
  end
  else
  begin
    valid := Trunc(ACBrBAL1.UltimoPesoLido);
    {case valid of
      0:
        ShowMessage('TimeOut !' + sLineBreak + 'Coloque o produto sobre a Balan�a!');
      -1:
        ShowMessage('Peso Inst�vel ! ' + sLineBreak + 'Tente Nova Leitura');
      -2:
        ShowMessage('Peso Negativo !');
      -10:
        ShowMessage('Sobrepeso !');
    end;}
  end;
end;

procedure TfrmPesarPrato.prc_ImprimirComanda(ID_Cupom: Integer);
begin
  fDmCupomFiscal.cdsComandaRel.Close;
  fDmCupomFiscal.sdsComandaRel.CommandText := fDmCupomFiscal.ctComandaRel;
  fDmCupomFiscal.sdsComandaRel.ParamByName('ID').AsInteger := ID_Cupom;
  fDmCupomFiscal.cdsComandaRel.Open;

  fDmCupomFiscal.cdsComandaItem_Rel.Close;
  //fDmCupomFiscal.sdsComandaItem_Rel.ParamByName('ID').AsInteger := fDmCupomFiscal.cdsCupom_ConsID.AsInteger;
  fDmCupomFiscal.cdsComandaItem_Rel.Open;

  fComandaR := TfComandaR.Create(Self);
  fComandaR.fDmCupomFiscal := fDmCupomFiscal;
  fComandaR.RLReport1.PrintDialog := False;
  if fDmCupomFiscal.cdsCupomParametrosUSA_COMANDA.AsString = 'P' then
    fComandaR.RLReport1.PreviewModal
  else
  if fDmCupomFiscal.cdsCupomParametrosUSA_COMANDA.AsString = 'S' then
    fComandaR.RLReport1.Print;
end;

procedure TfrmPesarPrato.prc_Grava_Cupom;
begin
  if not(fDmCupomFiscal.cdsCupomFiscal.State in [dsEdit,dsInsert]) then
    fDmCupomFiscal.cdsCupomFiscal.Edit;
  if fDmCupomFiscal.cdsParametrosUSA_NFCE.AsString <> 'S' then
  begin
    fDmCupomFiscal.cdsCupomFiscalVLR_TOTAL.AsFloat := fDmCupomFiscal.cdsCupomFiscalVLR_TOTAL.AsFloat + fDmCupomFiscal.cdsCupom_ItensVLR_TOTAL.AsFloat;
    fDmCupomFiscal.cdsCupomFiscalVLR_ICMS.AsFloat := fDmCupomFiscal.cdsCupomFiscalVLR_ICMS.AsFloat + fDmCupomFiscal.cdsCupom_ItensVLR_ICMS.AsFloat;
    fDmCupomFiscal.cdsCupomFiscalVLR_PRODUTOS.AsFloat := fDmCupomFiscal.cdsCupomFiscalVLR_PRODUTOS.AsFloat + fDmCupomFiscal.cdsCupom_ItensVLR_TOTAL.AsFloat;
    fDmCupomFiscal.cdsCupomFiscalBASE_ICMS.AsFloat := fDmCupomFiscal.cdsCupomFiscalBASE_ICMS.AsFloat + fDmCupomFiscal.cdsCupom_ItensBASE_ICMS.AsFloat;

    fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO.AsFloat := fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO.AsFloat + fDmCupomFiscal.cdsCupom_ItensVLR_TRIBUTO.AsFloat;

    fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO_FEDERAL.AsFloat := fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO_FEDERAL.AsFloat + fDmCupomFiscal.cdsCupom_ItensVLR_TRIBUTO_FEDERAL.AsFloat;
    fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO_ESTADUAL.AsFloat := fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO_ESTADUAL.AsFloat + fDmCupomFiscal.cdsCupom_ItensVLR_TRIBUTO_ESTADUAL.AsFloat;
    fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO_MUNICIPAL.AsFloat := fDmCupomFiscal.cdsCupomFiscalVLR_TRIBUTO_MUNICIPAL.AsFloat + fDmCupomFiscal.cdsCupom_ItensVLR_TRIBUTO_MUNICIPAL.AsFloat;
  end;

  fDmCupomFiscal.qProximoCupom.Close;
  fDmCupomFiscal.qProximoCupom.ParamByName('FILIAL').AsInteger := fDmCupomFiscal.cdsCupomFiscalFILIAL.AsInteger;
  fDmCupomFiscal.qProximoCupom.ParamByName('TIPO').AsString    := 'COM';
  fDmCupomFiscal.qProximoCupom.Open;
  fDmCupomFiscal.cdsCupomFiscalNUMCUPOM.AsInteger   := fDmCupomFiscal.qProximoCupomNUMCUPOM.AsInteger + 1;
  fDmCupomFiscal.cdsCupomFiscalID_CLIENTE.AsInteger := fDmCupomFiscal.vClienteID;
  fDmCupomFiscal.cdsCupomFiscal.Post;
  fDmCupomFiscal.cdsCupomFiscal.ApplyUpdates(0);
end;

end.
