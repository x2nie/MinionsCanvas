unit igCore_Viewer;

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
{ Standard }
  Messages, Windows, SysUtils, Classes, Controls, Forms,StdCtrls, Graphics,
  ExtCtrls, Buttons, CommDlg, //Dlgs,
  ExtDlgs, Dialogs,
{ Graphics32 }
  GR32_Image;
{ GraphicsMagic }


type
  TigCoreViewer = class(TImgView32)
  private

  protected

  public
    //for universal file dialog
    constructor Create(AOwner : TComponent); override;
    procedure LoadFromFile(const FileName: string); virtual; abstract;
    function GetReaderFilter : string; virtual;
    function GetWriterFilter : string; virtual; 

  published

  end;

  TigCoreViewerClass = class of TigCoreViewer;


implementation

//uses  Consts;
resourcestring
    SDefaultFilter = 'All files (*.*)|*.*';


{ TigCoreViewer }

constructor TigCoreViewer.Create(AOwner: TComponent);
begin
  inherited;
  self.Bitmap.ResamplerClassName := 'TKernelResampler';
end;

function TigCoreViewer.GetReaderFilter: string;
begin
  Result := SDefaultFilter;
end;

function TigCoreViewer.GetWriterFilter: string;
begin
  Result := SDefaultFilter;
end;

end.
