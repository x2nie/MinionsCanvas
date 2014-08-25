unit igCore_rw;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 *
 * The Initial Developer of this unit are
 *  x2nie - Fathony Luthfillah  <x2nie@yahoo.com>
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)
 
interface

uses
  SysUtils, Classes;

type

  TigVersionRec = packed record
    case Integer of
      0: (AsLongWord : Cardinal);
      1: (AsInteger  : Integer);
      2: (BEMajor, BEMinor: SmallInt);// BigEndian
      3: (Minor, Major: Word);        // LitteEndian
      4: (Words: array [0..1] of Word);
      5: (Bytes: array [0..3] of Byte);
  end;

  TigFileHeader = record
    FileID    : Cardinal;       // file ID code 
    Version   : TigVersionRec;  // version of the stream/file format
    ItemCount : Cardinal;       // indicating how many items are in this file
  end;


  TigConverter = class(TObject)
  public
    constructor Create; virtual;
    class function WantThis(AStream: TStream): Boolean; virtual; abstract;
    procedure LoadFromStream(AStream: TStream; ACollection: TCollection); virtual; abstract;
    procedure LoadItemFromStream(AStream: TStream; AItem: TCollectionItem); virtual; abstract;
    procedure SaveToStream(AStream: TStream; ACollection: TCollection); virtual; abstract;
    procedure SaveItemToStream(AStream: TStream; AItem: TCollectionItem); virtual; abstract;
  end;

  TigConverterClass = class of TigConverter;
  TigArrayOfConverterClass = array of TigConverterClass;


  PigFileFormat = ^TigFileFormat;
  TigFileFormat = record
    ConverterClass : TigConverterClass;
    Extension      : string;
    Description    : string;
    DescResID      : Integer;
  end;

  
  TigFileFormatsList = class(TList)
  private
    FShowAllExts      : Boolean;
    FAllSupportedFiles: string;

    function AvailableClass(AClass: TigConverterClass): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const AExt, ADesc: string; const ADescID: Integer;
      AClass: TigConverterClass);

    procedure Remove(AClass: TigConverterClass);

    procedure BuildFilterStrings(AConverterClass: TigConverterClass;
      var ADescriptions, AFilters: string);
    
    function FindExt(const AExt: string): TigConverterClass;
    function FindClassName(const AClassname: string): TigConverterClass;
    function Readers(const AIndex: Integer): TigConverterClass;
    function ReadersByExt(const AExt : string): TigArrayOfConverterClass;

    property ShowAllExts       : Boolean read FShowAllExts       write FShowAllExts;
    property AllSupportedFiles : string  read FAllSupportedFiles write FAllSupportedFiles;
  end;

implementation

//uses  Consts;

constructor TigFileFormatsList.Create;
begin
  inherited Create;

  FShowAllExts       := True;
  FAllSupportedFiles := 'All supported Files';

  //Add('wmf', SVMetafiles, 0, TMetafile);
  //Add('emf', SVEnhMetafiles, 0, TMetafile);
  //Add('ico', SVIcons, 0, TIcon);
  //Add('bmp', SVBitmaps, 0, TBitmap);
end;

destructor TigFileFormatsList.Destroy;
var
  I: Integer;
begin
  for I := (Count - 1) downto 0 do
    Dispose(PigFileFormat(Items[I]));

  inherited Destroy;
end;

procedure TigFileFormatsList.Add(const AExt, ADesc: string;
  const ADescID: Integer; AClass: TigConverterClass);
var
  LNewRec: PigFileFormat;
begin
//  if AvailableClass(AClass) then Exit;

  New(LNewRec);
  with LNewRec^ do
  begin
    Extension      := AnsiLowerCase(AExt);
    ConverterClass := AClass;
    Description    := ADesc;
    DescResID      := ADescID;
  end;

  inherited Add(LNewRec);
end;

function TigFileFormatsList.FindExt(const AExt: string): TigConverterClass;
var
  I   : Integer;
  LExt: string;
begin
  LExt := AnsiLowerCase(AExt);

  if LExt[1] = '.' then
    LExt := Copy(LExt, 2, 100);

  for I := (Count - 1) downto 0 do
    with PigFileFormat(Items[I])^ do
      if Extension = LExt then
      begin
        Result := ConverterClass;
        Exit;
      end;
      
  Result := nil;
end;

function TigFileFormatsList.FindClassName(
  const AClassName: string): TigConverterClass;
var
  I: Integer;
begin
  for I := (Count - 1) downto 0 do
  begin
    Result := PigFileFormat(Items[I])^.ConverterClass;

    if Result.ClassName = AClassName then
    begin
      Exit;
    end;
  end;
  
  Result := nil;
end;

function TigFileFormatsList.AvailableClass(
  AClass:TigConverterClass): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := (Count - 1) downto 0 do
    if AClass = PigFileFormat(Items[I])^.ConverterClass then
      begin
        Result := True;
        Break;
      end;
end;

procedure TigFileFormatsList.Remove(AClass: TigConverterClass);
var
  I: Integer;
  P: PigFileFormat;
begin
  for I := (Count - 1) downto 0 do
  begin
    P := PigFileFormat(Items[I]);

    if P^.ConverterClass.InheritsFrom(AClass) then
    begin
      Dispose(P);
      Delete(I);
    end;
  end;
end;

procedure TigFileFormatsList.BuildFilterStrings(
  AConverterClass: TigConverterClass;
  var ADescriptions, AFilters: string);
var
  C, I  : Integer;
  P     : PigFileFormat;
  LExts : TStringList;
begin
  LExts := TStringList.Create;
  try
    ADescriptions := '';
    AFilters      := '';
    C             := 0;

    for I := (Count - 1) downto 0 do
    begin
      P := PigFileFormat(Items[I]);

      if P^.ConverterClass.InheritsFrom(AConverterClass) and
         (P^.Extension <> '') then
      begin
        with P^ do
        begin
          if C <> 0 then
          begin
            ADescriptions := ADescriptions + '|';

            if LExts.IndexOf(Extension) < 0 then
              AFilters := AFilters + ';';
          end;

          if (Description = '') and (DescResID <> 0) then
            Description := LoadStr(DescResID);

          FmtStr(ADescriptions, '%s%s (*.%s)|*.%2:s',
                 [ADescriptions, Description, Extension]);
                 
          if LExts.IndexOf(Extension) < 0 then
          begin
            FmtStr(AFilters, '%s*.%s', [AFilters, Extension]);
            LExts.Add(Extension)
          end;

          Inc(C);
        end;
      end;
    end;

  finally
    LExts.Free;
  end;
  
  if FShowAllExts and (C > 1) then
  begin
    FmtStr(ADescriptions, '%s (%s)|%1:s|%s',
           [{sAllFilter} FAllSupportedFiles, AFilters, ADescriptions]);
  end;
end;

function TigFileFormatsList.Readers(const AIndex: Integer): TigConverterClass;
var
  P: PigFileFormat;
begin
  //unsafe!!!!!
  P      := PigFileFormat(Items[AIndex]);
  Result := P^.ConverterClass;
end;

{ TigConverter }

constructor TigConverter.Create;
begin

end;

function TigFileFormatsList.ReadersByExt(
  const AExt: string): TigArrayOfConverterClass;
var
  L,I   : Integer;
  LExt: string;
begin
  LExt := AnsiLowerCase(AExt);

  if LExt[1] = '.' then
    LExt := Copy(LExt, 2, 100);

  SetLength(Result,0);
  L := 0;

  for I := (Count - 1) downto 0 do
    with PigFileFormat(Items[I])^ do
      if Extension = LExt then
      begin
        Inc(L);
        SetLength(Result,L);
        Result[L-1] := ConverterClass;        
      end;
end;

end.
