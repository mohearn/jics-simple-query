﻿<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Admin_View.ascx.cs"
    Inherits="CUS.ICS.SimpleQuery.Admin_View" %>
<link href="<%= ResolveUrl("~/ClientConfig/css/jqueryDataTable.css") %>" rel="stylesheet"
    type="text/css" />
    <script type="text/javascript" src="<%= ResolveUrl("~/ClientConfig/js/jquery.dataTables.js") %>"></script>
<script type="text/javascript">

    jQuery(function ($) {
        var PortletLocation;
        var data;
        var columns;
        var initialized = false;

        $(document).ready(function () {
            PortletLocation = '<%= ResolveUrl("~/Portlets/CUS/ICS/SimpleQuery/") %>';

            if ($.fn.dataTableExt == undefined)
                $.getScript('<%= ResolveUrl("~/ClientConfig/js/jquery.dataTables.min.js") %>');


            $('#<%= btnTestConnection.ClientID %>').bind('click', function () {
                try {
                    TestConnection();
                } catch (e) {

                }
                return false;
            });

            $('#<%= btnTestQuery.ClientID %>').bind('click', function () {
                try {
                    TestQuery();
                } catch (e) {

                }
                return false;
            });

            $('#tblDataTable tbody td img').live('click', function () {
                var oTable = $('#tblDataTable').dataTable();
                var nTr = this.parentNode.parentNode;
                if (this.src.match('details_close')) {
                    /* This row is already open - close it */
                    this.src = '<%= ResolveUrl("~/ClientConfig/images/datatables/details_open.png") %>';
                    oTable.fnClose(nTr);
                } else {
                    /* Open this row */
                    this.src = '<%= ResolveUrl("~/ClientConfig/images/datatables/details_close.png") %>';
                    oTable.fnOpen(nTr, fnFormatDetails(nTr, columns, oTable), 'details');
                }
            });

            // Hide or Show the Other Connection String Box based on the dropdown value.
            $('#<%= ddlConfigFile.ClientID %>').change(function () {
                if ($(this).val() == '')
                    $('#<%= tbConfigFile.ClientID %>').show();
                else {
                    $('#<%= tbConfigFile.ClientID %>').hide();
                }
            });

            $('#<%= chkExportLiteral.ClientID %>').change(function () {
                if ($(this).attr('checked')) {
                    $('#<%= trLiteralFormat.ClientID %>').attr("style", "");
                } else {
                    $('#<%= trLiteralFormat.ClientID %>').hide();
                }
            });

            $('#<%= chkDisplayResultsMinimized.ClientID %>').change(function () {
                if ($(this).attr('checked')) {
                    $('#<%= pLinkText.ClientID %>').show();
                    $('#<%= pDescription.ClientID %>').show();
                } else {
                    $('#<%= pLinkText.ClientID %>').hide();
                    $('#<%= pDescription.ClientID %>').hide();
                }
            });

            var jicsOutputName = $("#<%= rbJICSOutputGrid.ClientID %>").attr('name');
            $("input[name='" + jicsOutputName + "']").change(function () {

                $('#<%=divJICSOutputGridSettings.ClientID %>').hide();
                $('#<%=divJICSOutputDataTablesSettings.ClientID %>').hide();

                switch ($("input[name='" + jicsOutputName + "']:checked").val()) {
                    case "grid":
                        $('#<%=divJICSOutputGridSettings.ClientID %>').show();
                        break;
                    case "datatables":
                        $('#<%=divJICSOutputDataTablesSettings.ClientID %>').show();
                        break;
                    case "csv":
                        break;
                    case "xml":
                        break;
                    case "literal":
                        break;
                }
            });
            var goOutputName = $("#<%= rbGOOutputGrid.ClientID %>").attr('name');
            $("input[name='" + goOutputName + "']").change(function () {

                $('#<%=divGOOutputGridSettings.ClientID %>').hide();
                $('#<%=divGOOutputMasterDetailSettings.ClientID %>').hide();

                switch ($("input[name='" + goOutputName + "']:checked").val()) {
                    case "grid":
                        $('#<%=divGOOutputGridSettings.ClientID %>').show();
                        break;
                    case "masterdetail":
                        $('#<%=divGOOutputMasterDetailSettings.ClientID %>').show();
                        break;
                    case "csv":
                        break;
                    case "xml":
                        break;
                    case "literal":
                        break;
                }
            });

        });


        function TestConnection() {
            $('#message').hide();
            $('#error').hide();
            $('#<%= btnTestConnection.ClientID %>').attr('disabled', true);
            $.ajax({
                url: PortletLocation + "Admin.ashx",
                data: { action: "TestConnection", _connectionFile: $('#<%= ddlConfigFile.ClientID %>').val() == "" ? $('#<%= tbConfigFile.ClientID %>').val() : $('#<%= ddlConfigFile.ClientID %>').val(), _portletID: '<%= ParentPortlet.PortletDisplay.Portlet.ID.AsGuid %>' },
                dataType: "json",
                type: "POST",
                success: function (ret) {
                    if (ret.d.success) {
                        $('#<%= btnTestConnection.ClientID %>').attr('disabled', false);
                        $('#message').show().html(ret.d.message);
                    } else {
                        $('#<%= btnTestConnection.ClientID %>').attr('disabled', false);
                        $('#error').show().html(ret.d.message + "<br />" + ret.d.exception);
                    }
                }
            });
        }

        function TestQuery() {
            $('#message').hide();
            $('#error').hide();
            $('#<%= btnTestQuery.ClientID %>').attr('disabled', true);
            $.ajax({
                url: PortletLocation + "Admin.ashx",
                data: { action: "TestQuery",
                        _connectionFile: $('#<%= ddlConfigFile.ClientID %>').val() == "" ? $('#<%= tbConfigFile.ClientID %>').val() : $('#<%= ddlConfigFile.ClientID %>').val(),
                        _portletID: '<%= ParentPortlet.PortletDisplay.Portlet.ID.AsGuid %>',
                        _queryString: $('#<%= txtQuery.ClientID %>').val(),
                        _expandedColumns: $('#<%= tbJICSDataTablesExpandedColumns.ClientID %>').val(),
                        _columnLabels: $('#<%= txtColumnLabels.ClientID %>').val(), 
                        _queryTimeout: $('#<%= tbQueryTimeout.ClientID %>').val(),
                        _hostId: $('#<%= tbTestHostId.ClientID %>').val()
                    },
                dataType: "json",
                type: "POST",
                success: function (ret) {
                    if (ret.d.success) {
                        $('#message').show().html(ret.d.message).append($('<span></span>').html('View Results').addClass('viewResults').bind('click', function () {
                            ViewResults();
                        }));
                        data = ret.d.data;
                        columns = ret.d.columns;
                        $('#<%= btnTestQuery.ClientID %>').attr('disabled', false);
                    } else {
                        $('#<%= btnTestQuery.ClientID %>').attr('disabled', false);
                        $('#error').show().html(ret.d.message + "<br />" + ret.d.exception);
                    }
                }
            });
        }

        function fnFormatDetails(nTr, aoColumns, oTable) {

            var aData = oTable.fnGetData(nTr);
            var sOut = '<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">';
            for (var column in aoColumns) {
                if (aoColumns[column].bDetail) {
                    sOut += '<tr><td><strong>' + aoColumns[column].sTitle + ':</strong> ' + aData[column] + '</td></td>';
                }
            }
            sOut += '</table>';

            return sOut;
        }

        function ViewResults() {
            $('#tblDataTable').dataTable({ "sPaginationType": "full_numbers", "aaData": data, "aoColumns": columns, "aaSorting": [] });
            $('#divViewResults').dialog({
                title: 'Results',
                close: function () {
                    var oTable = $('#tblDataTable').dataTable();
                    oTable.fnDestroy();
                    $('#tblDataTable').children("tbody").empty();
                    $('#tblDataTable').children("thead").empty();
                    $(this).dialog('destroy').hide();
                },
                width: '100%',
                height: '500',
                modal: true
            }).show();
            $('#tblDataTable').css('width', '100%');
        }
    });
</script>
<style type="text/css">
    #message, #error
    {
        display: none;
    }
    .viewResults
    {
        cursor: pointer;
        font-weight: bold;
        text-decoration: underline;
    }
    .hidden
    {
        display: none;
    }
    #tblSettings tbody tr td
    {
        vertical-align: top;
    }
    #tblSettings {
        border: none;        
    }
</style>
<div class="pContent">
    <div id="divViewResults" style="display: none; width: 100%">
        <table id="tblDataTable" class="display" style="width: 100%">
        </table>
    </div>
    <div class="pSection">
        <div id="message" class="feedbackMessage">
        </div>
        <div id="error" class="feedbackError">
        </div>
        <table cellpadding="5" id="tblSettings">
            <tr>
                <td width="125"><strong>Query Title</strong></td>
                <td width="350"><asp:TextBox runat="server" ID="tbQueryTitle"></asp:TextBox></td>
            </tr>
            <tr>
                <td>
                    <strong>Connection</strong><asp:Button ID="btnTestConnection" runat="server" Text="Test" style="float:right">
                    </asp:Button>
                </td>
                <td>
                    <p>
                        <asp:DropDownList ID="ddlConfigFile" runat="server">
                        </asp:DropDownList>
                        <asp:TextBox ID="tbConfigFile" runat="server"></asp:TextBox>
                    </p>
                    
                </td>
                <td>
                    Provide an ODBC connection string or the name of an xml file containing the connection
                    string to be used for this query. If providing a file name, it must reside in the
                    ClientConfig folder, the name must end in .config, and the first text element in
                    the file will be assumed to contain a connection string. For help, go to <a href="http://www.connectionstrings.com/"
                        target="_blank">ConnectionStrings.com</a>
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Query</strong><asp:Button ID="btnTestQuery" runat="server" Text="Test" style="float:right"></asp:Button>
                </td>
                <td>
                    <p>
                        <asp:TextBox ID="txtQuery" Columns="40" runat="server" Rows="25" TextMode="MultiLine"></asp:TextBox></p>
                </td>
                <td>
                    <p>
                        Enter a select query here. Delete, insert,&nbsp;update, or other query types will
                        be rejected unless special permissions have been granted by the Portal Administrator.</p>
                    <p>
                        Place any of the following variables into your query text and they will be replaced
                        by current data as the query is being executed:
                    </p>
                    <ul>
                        <li>@@HostID - the ERP ID number for the logged in JICS user</li>
                        <li>@@Username - the JICS username for the logged in user</li>
                        <li>@@EmailAddress - the JICS email address for the logged in user</li>
                        <li>@@FirstName - the JICS username for the logged in user</li>
                        <li>@@LastName - the JICS username for the logged in user</li>
                        <li>@@MiddleName - the JICS username for the logged in user</li>
                        <li>@@DisplayName - combination of Preferred First and Last names for the logged in
                            user</li>
                        <li>@@CurrentYear - the ERP system academic year configured as current</li>
                        <li>@@CurrentSession - the ERP system academic session configured as current</li>
                    </ul>
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Query Timeout</strong>
                </td>
                <td>
                    <asp:TextBox ID="tbQueryTimeout" runat="server"></asp:TextBox>
                </td>
                <td>
                    The number of seconds to allow the query to run without quitting. If a zero or blank
                    value is provided, the default (usually 30 seconds) will apply.
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Row Limit</strong>
                </td>
                <td>
                    <asp:TextBox runat="server" ID="tbRowLimit"></asp:TextBox>
                </td>
                <td>
                    This will limit the number of rows returned to the screen, but will <em>not</em> limit the number of rows returned in an export. If blank or 0, no limit is enforced.
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Test HostID</strong>
                </td>
                <td>
                    <asp:TextBox runat="server" ID="tbTestHostId"></asp:TextBox>
                </td>
                <td>
                    Subsitute current HostID with this. Only used here for testing.
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Column Headings</strong>
                </td>
                <td>
                    <asp:TextBox ID="txtColumnLabels" Columns="30" runat="server" Visible="True">Column1Title,Column2Title,etc</asp:TextBox>
                </td>
                <td>
                    If you provide a comma-separated set of names, they will be used as display column
                    headings in place of the query column names. For example: "Column One, Column Two,
                    Column Three" (without the quotes)
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Export Options</strong>
                </td>
                <td>
                    <asp:CheckBox runat="server" ID="chkExportXls" Text="Excel" /><br />
                    <asp:CheckBox runat="server" ID="chkExportXml" Text="XML" /><br />
                    <asp:CheckBox runat="server" ID="chkExportCsv" Text="CSV" /><br />
                    <asp:CheckBox runat="server" ID="chkExportLiteral" Text="Literal" />
                </td>
            </tr>
            <tr id="trLiteralFormat" runat="server">
                <td>
                    &nbsp;
                </td>
                <td>
                    <p>
                        Format:
                        <asp:TextBox runat="server" ID="tbExportLiteralPattern"></asp:TextBox></p>
                </td>
                <td>
                    <p>
                        Format for the literal string return. Example:<br />
                        &lt;?xml version="1.0" encoding="utf-8"?&gt;&lt;RootElement&gt;{0}&lt;/RootElement&gt;</p>
                </td>
            </tr>
            <tr>
                <td colspan="3">
                    <h4>
                        JICS Display</h4>
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Portlet Display</strong>
                </td>
                <td>
                    <asp:CheckBox runat="server" ID="chkDisplayResultsMinimized" Text="Show results in both Minimized and Maximized View"/>
                <td/>
                <td>If not set, a link and description will be shown in the mimized view.</td>
            </tr>
            <tr>
                <td><strong>Link Text </strong></td>
                <td>
                    <p id="pLinkText" runat="server">
                        <asp:TextBox runat="server" ID="tbLinkText" Columns="40"></asp:TextBox>
                    </p>
                </td>
                <td>Uses &quot;Show Results&quot; if not set</td>
            </tr>
            <tr>
                <td><strong>Description</strong></td>
                <td>
                    <p id="pDescription" runat="server">
                        <asp:TextBox runat="server" ID="tbDescription" Rows="7" Columns="40" TextMode="MultiLine"></asp:TextBox>
                    </p>
                </td>
            </tr>
            <tr>
                <td>
                    &nbsp;
                </td>
                <td>
                    <asp:CheckBox runat="server" ID="chkJICSAllowExports" Text="Allow Exports" />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Output Settings:</strong>
                </td>
                <td>
                    <asp:CheckBox runat="server" ID="chkJICSAsync" Text="Use Asynchronous Loading" /><br /><br/>
                    <input type="radio" id="rbJICSOutputGrid" name="rbJICSOutput" value="grid" runat="server" />
                    <label for="<%= rbJICSOutputGrid.ClientID %>">
                        Plain Grid</label><br />
                    <div id="divJICSOutputGridSettings" runat="server" style="margin-left:20px;">
                        <asp:CheckBox runat="server" ID="chkJICSShowColumnHeadings" Text="Show Column Headings" /><br />
                        <asp:CheckBox runat="server" ID="chkJICSGridShowGridlines" Text="Show Gridlines" /><br />
                        Cell Padding:
                        <asp:TextBox runat="server" ID="tbJICSGridCellPadding"></asp:TextBox><br />
                        <asp:CheckBox runat="server" ID="chkJICSGridAltRowColors" Text="Use Alternating Row Colors" /><br />
                        
                    </div>
                    <input type="radio" id="rbJICSOutputDataTables" name="rbJICSOutput" value="datatables"
                        runat="server" />
                    <label for="<%= rbJICSOutputDataTables.ClientID %>">
                        Dynamic Data Table</label><br />
                    <div id="divJICSOutputDataTablesSettings" runat="server" style="margin-left:20px;">
                        Expanded Display Columns
                        <asp:TextBox runat="server" ID="tbJICSDataTablesExpandedColumns"></asp:TextBox>
                    </div>
                    
                    <input type="radio" id="rbJICSOutputXML" name="rbJICSOutput" value="xml" runat="server" />
                    <label for="<%= rbJICSOutputXML.ClientID %>">
                        XML</label><br />
                    <input type="radio" id="rbJICSOutputCSV" name="rbJICSOutput" value="csv" runat="server" />
                    <label for="<%= rbJICSOutputCSV.ClientID %>">
                        CSV</label><br />
                    <input type="radio" id="rbJICSOutputLiteral" name="rbJICSOutput" value="literal"
                        runat="server" />
                    <label for="<%= rbJICSOutputLiteral.ClientID %>">
                        Literal</label>
                </td>
                <td>
                    <strong>Plain Grid</strong> shows the data in a simple static table on the page.<br />
                    <strong>Dynamic Data Table</strong> presents query results in a sortable, searchable,
                    paged grid using jQuery DataTables. This will ignore any table formatting specified
                    in portlet Settings.
                </td>
            </tr>
             <tr>
                <td colspan="3">
                    <h4>
                        JICS Go Display</h4>
                </td>
            </tr>
            <tr>
                <td>
                    &nbsp;
                </td>
                <td>
                    <asp:CheckBox runat="server" ID="chkGOAllowExports" Text="Allow Exports" />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Output Settings:</strong>
                </td>
                <td>
                    <input type="radio" id="rbGOOutputNone" name="rbGOOutput" value="none" runat="server" />
                    <label for="<%= rbGOOutputNone.ClientID %>">None</label><br />
                    <input type="radio" id="rbGOOutputGrid" name="rbGOOutput" value="grid" runat="server" />
                    <label for="<%= rbGOOutputGrid.ClientID %>">
                        Plain Grid</label><br />
                    <div id="divGOOutputGridSettings" runat="server" style="margin-left:20px;">
                        <asp:CheckBox runat="server" ID="chkGOGridShowColumnHeadings" Text="Show Column Headings" /><br />
                        <asp:CheckBox runat="server" ID="chkGOGridShowGridlines" Text="Show Gridlines" /><br />
                        Cell Padding:
                        <asp:TextBox runat="server" ID="tbGOGridCellPadding"></asp:TextBox><br />
                        <asp:CheckBox runat="server" ID="chkGOGridAltRowColors" Text="Use Alternating Row Colors" /><br />
                    </div>
                    <input type="radio" id="rbGOOutputMasterDetail" name="rbGOOutput" value="masterdetail"
                        runat="server" />
                    <label for="<%= rbGOOutputMasterDetail.ClientID %>">
                        Master-Detail</label><br />
                    <div id="divGOOutputMasterDetailSettings" runat="server" style="margin-left: 20px;">
                        Detail Display Columns
                        <asp:TextBox runat="server" ID="tbGOOutputMasterDetailDisplayColumns"></asp:TextBox>
                    </div>
                    <input type="radio" id="rbGOOutputXML" name="rbGOOutput" value="xml" runat="server" />
                    <label for="<%= rbGOOutputXML.ClientID %>">
                        XML</label><br />
                    <input type="radio" id="rbGOOutputCSV" name="rbGOOutput" value="csv" runat="server" />
                    <label for="<%= rbGOOutputCSV.ClientID %>">
                        CSV</label><br />
                    <input type="radio" id="rbGOOutputLiteral" name="rbGOOutput" value="literal"
                        runat="server" />
                    <label for="<%= rbGOOutputLiteral.ClientID %>">
                        Literal</label>
                </td>
                <td>
                    <strong>Plain Grid</strong> shows the data in a simple static table on the page.<br />
                    <strong>Master-Detail Mode</strong> presents results with the first column being displayed only.  On tap (click) the rest of the columns specified in "Detail Display Columns" are shown.
                </td>
            </tr>
            <tr>
                <td colspan="3" style="text-align: center;">
                    
                    <asp:Button ID="btnSave" runat="server" Text="Save"></asp:Button><br />
                    <br />
                    <asp:Button ID="btnCancel" runat="server" Text="Exit"></asp:Button>
                    
                </td>
            </tr>
        </table>
    </div>
</div>