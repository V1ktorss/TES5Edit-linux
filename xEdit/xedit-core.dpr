{******************************************************************************


  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

{$I xeDefines.inc}
{$DEFINE XEDIT_HEADLESS}

program xedit_core;

{$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished]) PROPERTIES([vcPrivate, vcProtected, vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic, vcPublished])}

uses
  SysUtils,
  xeInit in 'xEdit/xeInit.pas',
  wbInterface in 'Core/wbInterface.pas';

begin
  SysUtils.FormatSettings.DecimalSeparator := '.';

  xeInitStyles;
  if not xeDoInit then
    Halt(1);

  WriteLn(wbApplicationTitle);
end.
