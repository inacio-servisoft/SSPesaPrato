program SSPesaPrato;

uses
  Forms,
  DmdDatabase in '..\ssfacil\DmdDatabase.pas' {DmDatabase: TDataModule},
  UEscolhe_Filial in '..\ssfacil\UEscolhe_Filial.pas' {frmEscolhe_Filial},
  rsDBUtils in '..\rslib\nova\rsDBUtils.pas',
  LogProvider in '..\logs\src\LogProvider.pas',
  LogTypes in '..\logs\src\LogTypes.pas',
  Classe.CalcularRateio in '..\SSNFCe\Classes\Classe.CalcularRateio.pas',
  uImpFiscal_Elgin in '..\SSNFCe\uImpFiscal_Elgin.pas',
  TelaAutenticaUsuario in '..\SSNFCe\TelaAutenticaUsuario.pas' {FormTelaAutenticaUsuario},
  UPesarPrato in 'UPesarPrato.pas' {frmPesarPrato},
  uComandaR in '..\SSNFCe\uComandaR.pas' {fComandaR},
  uDmCupomFiscal in '..\SSNFCe\uDmCupomFiscal.pas' {dmCupomFiscal: TDataModule},
  uImpFiscal_Bematech in '..\SSNFCe\uImpFiscal_Bematech.pas',
  uImpFiscal_Daruma in '..\SSNFCe\uImpFiscal_Daruma.pas',
  uUtilDaruma in '..\SSNFCe\uUtilDaruma.pas',
  uUtilPadrao in '..\SSNFCe\uUtilPadrao.pas',
  uUtilBematech in '..\SSNFCe\uUtilBematech.pas',
  uCupomFiscalParcela in '..\SSNFCe\uCupomFiscalParcela.pas' {fCupomFiscalParcela},
  uCalculo_CupomFiscal in '..\SSNFCe\uCalculo_CupomFiscal.pas',
  uDmParametros in '..\SSNFCe\uDmParametros.pas' {dmParametros: TDataModule},
  UDMCadExtComissao in '..\ssfacil\UDMCadExtComissao.pas' {DMCadExtComissao: TDataModule},
  UDMGravarFinanceiro in '..\ssfacil\UDMGravarFinanceiro.pas' {DMGravarFinanceiro: TDataModule},
  uGrava_Erro in '..\ssfacil\uGrava_Erro.pas',
  USenha in '..\ssfacil\USenha.pas' {frmSenha},
  uUtilCliente in '..\ssfacil\uUtilCliente.pas',
  USel_Produto_Preco in '..\ssfacil\USel_Produto_Preco.pas' {frmSel_Produto_Preco};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDmDatabase, DmDatabase);
  Application.CreateForm(TdmParametros, dmParametros);
  Application.CreateForm(TfrmPesarPrato, frmPesarPrato);
  Application.Run;
end.
