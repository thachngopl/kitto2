{-------------------------------------------------------------------------------
   Copyright 2012 Ethea S.r.l.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-------------------------------------------------------------------------------}

unit Kitto.Ext.Controller;

{$I Kitto.Defines.inc}

interface

uses
  SysUtils
  , Classes
  , EF.Intf
  , EF.ObserverIntf
  , EF.Tree
  , EF.Types
  , Kitto.JS.Base
  , Ext.Base
  , Kitto.Types
  , Kitto.Metadata.Views
  , Kitto.JS
  ;

type
  /// <summary>
  ///  Interface implemented by objects that can be activated in some way,
  ///  for example put into tab pages.
  /// </summary>
  IKExtActivable = interface(IEFInterface)
    ['{D6B1AA36-C8D7-4D20-856A-7DCC7DB50423}']
    procedure Activate;
  end;

  /// <summary>
  ///  Holds a list of registered controller classes.
  /// </summary>
  /// <remarks>
  ///  Classes passed to RegisterClass and UnregisterClass must implement
  ///  IKController, otherwise an exception is raised.
  /// </remarks>
 { TODO :
allow to overwrite registrations in order to override predefined controllers;
keep track of all classes registered under the same name to handle
de-registration gracefully. }
  TKExtControllerRegistry = class(TEFRegistry)
  private
    class var FInstance: TKExtControllerRegistry;
    class function GetInstance: TKExtControllerRegistry; static;
  protected
    procedure BeforeRegisterClass(const AId: string; const AClass: TClass);
      override;
  public
    class destructor Destroy;
  public
    class property Instance: TKExtControllerRegistry read GetInstance;
    procedure RegisterClass(const AId: string; const AClass: TExtObjectClass);
  end;

  /// <summary>
  ///  Queries the registry to create controllers by class Id. It is
  ///  friend to TKControllerRegistry.
  /// </summary>
  TKExtControllerFactory = class
  private
    class var FInstance: TKExtControllerFactory;
    class function GetInstance: TKExtControllerFactory; static;
    function InvokeBooleanStaticMethod(const AClass: TClass; const AMethodName: string;
      const ADefaultResult: Boolean): Boolean;
  public
    class destructor Destroy;
    class property Instance: TKExtControllerFactory read GetInstance;

    /// <summary>
    ///  Creates a controller for the specified view.
    /// </summary>
    /// <param name="AOwner">
    ///  Owner for the created object (only used if AContainer is nil,
    ///  otherwise the container is the owner).
    /// </param>
    /// <param name="AView">
    ///  A reference to the view to control. The view object's lifetime is
    ///  managed externally.
    /// </param>
    /// <param name="AContainer">
    ///  Visual container to which to add the newly created controller.
    /// </param>
    /// <param name="AConfig">
    ///  Optional controller config node. If not specified, it is taken from
    ///  the view's 'Controller' node.
    /// </param>
    /// <param name="AObserver">
    ///  Optional observer that will receive events posted by the controller.
    /// </param>
    /// <param name="ACustomType">
    ///  Custom controller type, used to override the one specified in the view.
    /// </param>
    function CreateController(const AOwner: TJSBase; const AView: TKView;
      const AContainer: IJSControllerContainer; const AConfig: TEFNode = nil;
      const AObserver: IEFObserver = nil; const ACustomType: string = ''): IJSController;
  end;

implementation

uses
  System.Rtti;

{ TKExtControllerRegistry }

procedure TKExtControllerRegistry.BeforeRegisterClass(const AId: string;
  const AClass: TClass);
begin
  if not AClass.InheritsFrom(TExtObject) or not Supports(AClass, IJSController) then
    raise EKError.CreateFmt('Cannot register class %s (Id %s). Class is not a TExtObject descendant or does not support IKController.', [AClass.ClassName, AId]);
  inherited;
end;

class destructor TKExtControllerRegistry.Destroy;
begin
  FreeAndNil(FInstance);
end;

class function TKExtControllerRegistry.GetInstance: TKExtControllerRegistry;
begin
  if FInstance = nil then
    FInstance := TKExtControllerRegistry.Create;
  Result := FInstance;
end;

procedure TKExtControllerRegistry.RegisterClass(const AId: string;
  const AClass: TExtObjectClass);
begin
  inherited RegisterClass(AId, AClass);
end;

{ TKExtControllerFactory }

class destructor TKExtControllerFactory.Destroy;
begin
  FreeAndNil(FInstance);
end;

class function TKExtControllerFactory.GetInstance: TKExtControllerFactory;
begin
  if FInstance = nil then
    FInstance := TKExtControllerFactory.Create;
  Result := FInstance;
end;

function TKExtControllerFactory.InvokeBooleanStaticMethod(const AClass: TClass;
  const AMethodName: string; const ADefaultResult: Boolean): Boolean;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  LType := LContext.GetType(AClass);
  LMethod := LType.GetMethod(AMethodName);
  if Assigned(LMethod) then
    Result := LMethod.Invoke(AClass, []).AsBoolean
  else
    Result := ADefaultResult;
end;

function TKExtControllerFactory.CreateController(const AOwner: TJSBase;
  const AView: TKView; const AContainer: IJSControllerContainer; const AConfig: TEFNode;
  const AObserver: IEFObserver; const ACustomType: string): IJSController;
var
  LClass: TExtObjectClass;
  LSubject: IEFSubject;
  LObject: TExtObject;
  LType: string;
  LSupportsContainer: Boolean;
begin
  Assert(AView <> nil);
  Assert((AContainer <> nil) or (AOwner <> nil));

  LType := ACustomType;
  if LType = '' then
    if Assigned(AConfig) then
      LType := AConfig.AsExpandedString;
  if LType = '' then
    LType := AView.ControllerType;

  if LType = '' then
    raise EKError.Create('Cannot create controller. Unspecified type.');

  LClass := TExtObjectClass(TKExtControllerRegistry.Instance.GetClass(LType));
  LSupportsContainer := InvokeBooleanStaticMethod(LClass, 'SupportsContainer', True);

  if Assigned(AContainer) and LSupportsContainer then
    LObject := LClass.Create(AContainer.AsJSObject)
  else
    LObject := LClass.Create(AOwner);

  if not Supports(LObject, IJSController, Result) then
    raise EKError.Create('Object does not support IKController.');

  if Assigned(AContainer) and LSupportsContainer then
    AContainer.AddItem(LObject);

  if AConfig <> nil then
    Result.Config.Assign(AConfig)
  else
    Result.Config.Assign(AView.FindNode('Controller'));
  // Keep track of the SupportsContainer info fetched from the class for later use.
  Result.Config.SetBoolean('Sys/SupportsContainer', LSupportsContainer);
  Result.View := AView;
  if Assigned(AContainer) then
    AContainer.InitSubController(Result);
  if LSupportsContainer then
    Result.Container := AContainer;
  if Assigned(AObserver) and Supports(Result.AsObject, IEFSubject, LSubject) then
    LSubject.AttachObserver(AObserver);
end;

end.

