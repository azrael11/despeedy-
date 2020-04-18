{===============================================================================
  RadiantPlaylistForm Unit

  Radiant Shapes - Demo Source Unit

  Copyright � 2012-2014 by Raize Software, Inc.  All Rights Reserved.

  Modification History
  ------------------------------------------------------------------------------
  1.0    (29 Oct 2014)
    * Initial release.
===============================================================================}

unit RadiantPlaylistForm;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Objects,
  FMX.Layouts,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.ListView.Types,
  FMX.ListView,
  Data.DB,
  Datasnap.DBClient;

type
  TfrmPlaylist = class(TForm)
    lvwPlaylist: TListView;
    cdsPlaylist: TClientDataSet;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    procedure RatingChangeHandler( const Sender: TObject; const Item: TListViewItem; NewRating: Integer );
  public
    { Public declarations }
  end;

var
  frmPlaylist: TfrmPlaylist;

implementation

{$R *.fmx}

uses
  Radiant.Shapes;

const
  sRating = 'Rating';

{==========================}
{== TListItemRatingStars ==}
{==========================}

type
  TListItemRatingChangeEvent = procedure( const Sender: TObject; const Item: TListViewItem; NewRating: Integer ) of object;

  TListItemRatingStars = class( TListItemEmbeddedControl )
  private
    FRating: Integer;
    FStars: array[ 1..5 ] of TRadiantStar;
    FOnChange: TListItemRatingChangeEvent;

    procedure SetRating( Value: Integer );
    procedure StarClicked( Sender: TObject );
    procedure StarDblClicked( Sender: TObject );
  protected
    procedure Render( const Canvas: TCanvas; const DrawItemIndex: Integer; const DrawStates: TListItemDrawStates;
                      const SubPassNo: Integer ); override;
    procedure Change; dynamic;
  public
    constructor Create( const AOwner: TListItem ); override;
    destructor Destroy; override;

    property Rating: Integer
      read FRating
      write SetRating;

    property OnChange: TListItemRatingChangeEvent
      read FOnChange
      write FOnChange;
  end;


{==================================}
{== TListItemRatingStars Methods ==}
{==================================}

constructor TListItemRatingStars.Create( const AOwner: TListItem );
var
  I: Integer;
  X, Y: Single;
begin
  inherited;

  Align := TListItemAlign.Trailing;
  VertAlign := TListItemAlign.Center;
  Width := 125;
  Height := 30;
  Rating := 0;

  X := 0;
  Y := 0;

  for I := 1 to 5 do
  begin
    FStars[ I ] := TRadiantStar.Create( nil );
    FStars[ I ].Parent := Container;
    FStars[ I ].Name := 'Star' + IntToStr( I );
    FStars[ I ].Position.X := X + ( I - 1 ) * 25;
    FStars[ I ].Position.Y := Y;
    FStars[ I ].Width := 30;
    FStars[ I ].Height := 30;
    FStars[ I ].Fill.Kind := TBrushKind.None;
    FStars[ I ].Stroke.Color := TAlphaColors.LightGray;
    FStars[ I ].Stroke.Thickness := 1.5;
    FStars[ I ].Tag := I;
    FStars[ I ].OnClick := StarClicked;
    FStars[ I ].OnDblClick := StarDblClicked;
  end;
end;


destructor TListItemRatingStars.Destroy;
var
  I: Integer;
begin
  for I := 1 to 5 do
    FStars[ I ].Free;
  inherited;
end;


procedure TListItemRatingStars.SetRating( Value: Integer );
var
  I: Integer;
begin
  if FRating <> Value then
  begin
    FRating := Value;

    for I := 1 to 5 do
    begin
      if FRating >= I then
      begin
        FStars[ I ].Fill.Kind := TBrushKind.Solid;
        FStars[ I ].Fill.Color := TAlphaColors.Gold;
        FStars[ I ].Stroke.Color := TAlphaColors.DarkOrange;
      end
      else
      begin
        FStars[ I ].Fill.Kind := TBrushKind.None;
        FStars[ I ].Stroke.Color := TAlphaColors.Lightgray;
      end;
    end;
    Change;
    TListViewItem( Owner ).Invalidate;
  end;
end;


procedure TListItemRatingStars.Render( const Canvas: TCanvas; const DrawItemIndex: Integer; const DrawStates: TListItemDrawStates;
                                       const SubPassNo: Integer );
begin
  inherited;
end;


procedure TListItemRatingStars.Change;
begin
  if Assigned( FOnChange ) then
    FOnChange( Self, TListViewItem( Owner ), Rating );
end;


procedure TListItemRatingStars.StarClicked( Sender: TObject );
begin
  if Sender is TRadiantStar then
  begin
    Rating := TRadiantStar( Sender ).Tag;
  end;
end;


procedure TListItemRatingStars.StarDblClicked( Sender: TObject );
begin
  if Sender is TRadiantStar then
  begin
    Rating := 0;
  end;
end;


{==========================}
{== TfrmPlaylist Methods ==}
{==========================}

procedure TfrmPlaylist.FormCreate(Sender: TObject);
var
  I: Integer;
  Item: TListViewItem;
  ItemRatingStars: TListItemRatingStars;
begin
  cdsPlaylist.LoadFromFile( '.\RadiantPlayList.xml' );

  for I := 1 to cdsPlaylist.RecordCount do
  begin
    Item := lvwPlaylist.Items.Add;
    Item.Text := cdsPlaylist.FieldByName( 'Song' ).AsString;
    Item.Detail := cdsPlaylist.FieldByName( 'Artist' ).AsString;

    ItemRatingStars := TListItemRatingStars.Create( Item );
    ItemRatingStars.Name := sRating;
    ItemRatingStars.Rating := cdsPlaylist.FieldByName( 'Rating' ).AsInteger;
    ItemRatingStars.OnChange := RatingChangeHandler;

    cdsPlaylist.Next;
  end;
end;


procedure TfrmPlaylist.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  cdsPlaylist.MergeChangeLog;
  cdsPlaylist.SaveToFile( '.\RadiantPlayList.xml', TDataPacketFormat.dfXML );
end;


procedure TfrmPlaylist.RatingChangeHandler( const Sender: TObject; const Item: TListViewItem; NewRating: Integer );
begin
  cdsPlaylist.Filter := 'Song=' + QuotedStr( Item.Text );
  cdsPlaylist.Filtered := True;
  cdsPlaylist.Edit;
  cdsPlaylist.FieldByName( 'Rating' ).AsInteger := NewRating;
  cdsPlaylist.Post;
  cdsPlaylist.Filtered := False;
end;


end.
