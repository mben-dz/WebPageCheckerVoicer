﻿program WebPageCheckerVoicer;

uses
  System.SysUtils
, System.Classes
, System.Variants
, Winapi.Windows
, Winapi.WinInet
, Winapi.ActiveX
, ComObj
  ;

const
  CHECK_INTERVAL = 3000;  // 3 seconds
  NOTIFY_INTERVAL = 5000; // 5 seconds

type
  TLanguage = (langEnglish, langFrench, langArabic);

  I_WebChecker = interface ['{89F24919-B564-4D9F-819E-4E4AF4009750}']

    function SetURL(const aURL: string): I_WebChecker;
    function CheckService: I_WebChecker;
    function DisplayProgress: I_WebChecker;
    function Notify: I_WebChecker;
    procedure Introduce;
    function SetLanguage(aLang: TLanguage): I_WebChecker;
  end;

  TWebChecker = class(TInterfacedObject, I_WebChecker)
  strict private
    fURL: string;
    fServiceOpen: Boolean;
    fVoice: Variant;
    fLanguage: TLanguage;
    fMessages: array[TLanguage, 0..4] of string;
    procedure LoadMessages;
  private
    function SetURL(const aURL: string): I_WebChecker;
    function CheckService: I_WebChecker;
    function DisplayProgress: I_WebChecker;
    function Notify: I_WebChecker;
    procedure Introduce;
    function SetLanguage(aLang: TLanguage): I_WebChecker;
  public
    constructor Create;
  end;

constructor TWebChecker.Create;
begin inherited Create;

  fVoice := CreateOleObject('SAPI.SpVoice');
  LoadMessages;
  fLanguage := langEnglish;
end;

procedure TWebChecker.LoadMessages;
begin
  fMessages[langEnglish, 0] := 'Hello! I am your web page service checker. I will notify you if the service is open or closed.';
  fMessages[langEnglish, 1] := 'Checking service';
  fMessages[langEnglish, 2] := 'Service is Already OPEN!';
  fMessages[langEnglish, 3] := 'The service is open.';
  fMessages[langEnglish, 4] := 'The service is closed.';

  fMessages[langFrench, 0] := 'Bonjour! Je suis votre vérificateur de service de page web. Je vous notifierai si le service est ouvert ou fermé.';
  fMessages[langFrench, 1] := 'Vérification du service';
  fMessages[langFrench, 2] := 'Le service est déja OUVERT!';
  fMessages[langFrench, 3] := 'Le service est ouvert.';
  fMessages[langFrench, 4] := 'Le service est fermé.';

  fMessages[langArabic, 0] := 'مرحبًا! أنا فاحص خدمة صفحة الويب الخاص بك. سأخطرك إذا كانت الخدمة مفتوحة أو مغلقة.';
  fMessages[langArabic, 1] := 'جار التحقق من الخدمة';
  fMessages[langArabic, 2] := 'الخدمة مفتوحة مسبقا !';
  fMessages[langArabic, 3] := 'الخدمة مفتوحة.';
  fMessages[langArabic, 4] := 'الخدمة مغلقة.';
end;

function TWebChecker.SetLanguage(aLang: TLanguage): I_WebChecker;
begin
  Result    := Self;

  fLanguage := aLang;
end;

function TWebChecker.SetURL(const aURL: string): I_WebChecker;
begin
  Result := Self;

  fURL   := aURL;
end;

function TWebChecker.CheckService: I_WebChecker;
var
  L_hInet, L_hUrl: HINTERNET;
begin
  Result := Self;

  fServiceOpen := False;

  L_hInet := InternetOpen('WebChecker', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(L_hInet) then
  try
    L_hUrl := InternetOpenUrl(L_hInet, PChar(fURL), nil, 0, INTERNET_FLAG_RELOAD, 0);
    if Assigned(L_hUrl) then
    try
      fServiceOpen := True;
    finally
      InternetCloseHandle(L_hUrl);
    end;
  finally
    InternetCloseHandle(L_hInet);
  end;
end;

function TWebChecker.DisplayProgress: I_WebChecker;
const
  TotalSteps = 10;
var
  I: Integer;
begin
  Result := Self;

  Write(fMessages[fLanguage, 1]);
  for I := 1 to TotalSteps do
  begin
    Sleep(CHECK_INTERVAL div TotalSteps);
    Write('.');
  end;

  WriteLn;
end;

function TWebChecker.Notify: I_WebChecker;
begin
  Result := Self;

  if fServiceOpen then begin

    Writeln(fMessages[fLanguage, 2]);
    repeat
      fVoice.Speak(fMessages[fLanguage, 3], 0);
      Sleep(NOTIFY_INTERVAL);
      CheckService;
    until not fServiceOpen or (GetAsyncKeyState(VK_ESCAPE) <> 0); // Stop on ESC key

  end else
  begin
    Writeln(fMessages[fLanguage, 4]);
    fVoice.Speak(fMessages[fLanguage, 4], 0);
  end;
end;

procedure TWebChecker.Introduce;
begin
  fVoice.Speak(fMessages[fLanguage, 0], 0);
end;

var
  WebChecker: I_WebChecker;
  URL       : string;
  Language  : string;
begin
  Writeln('Web Page Service Checker');

  // Initialize COM library
  CoInitialize(nil);
  try
    WebChecker := TWebChecker.Create;
    WebChecker.Introduce;

    Write('Enter URL to check: ');
    Readln(URL);

    Write('Select language (en/fr/ar): ');
    Readln(Language);

    if Language = 'fr' then
      WebChecker.SetLanguage(langFrench)
    else if Language = 'ar' then
      WebChecker.SetLanguage(langArabic)
    else
      WebChecker.SetLanguage(langEnglish);

    while True do
    begin
      WebChecker.SetURL(URL)
                 .DisplayProgress
                 .CheckService
                 .Notify;
      Sleep(CHECK_INTERVAL);
    end;
  finally
    // Uninitialize COM library
    CoUninitialize;
  end;
end.
