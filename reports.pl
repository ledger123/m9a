#!/usr/bin/perl -w

$ENV{NLS_LANG}        = 'AMERICAN_AMERICA.AL32UTF8';
$ENV{ORACLE_SID}      = 'XE';
$ENV{ORACLE_HOME}     = '/usr/lib/oracle/xe/app/oracle/product/10.2.0/server';
$ENV{LD_LIBRARY_PATH} = '/usr/lib/oracle/xe/app/oracle/product/10.2.0/server/lib';

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use DBIx::Simple;
use Template;
use CGI::FormBuilder;
use Number::Format;

my $q  = new CGI;
my $nf = new Number::Format( -int_curr_symbol => '' );
my $tt = Template->new(
    {
        INCLUDE_PATH => [ '/var/www/munshi9/tmpl', '/var/www/lighttpd/munshi9/tmpl' ],
        INTERPOLATE  => 1,
    }
) || die "$Template::ERROR\n";

my %attr = ( PrintError => 0, RaiseError => 0 );    # Attributes to pass to DBI->connect() to disable automatic error checking
my $dbh = DBI->connect( "dbi:Oracle:XE", "munshi8", "munshi8", \%attr ) or die "Can't connect to database: ", $DBI::errstr, "\n";
my $dbs = DBIx::Simple->connect($dbh);

my $nextsub   = $q->param('nextsub');
my $action    = $q->param('action');
my $tmpl      = $q->param('tmpl');
my $id        = $q->param('id');
my $comp_code = $q->param('comp_code');

$nextsub = $q->param('nextsub');
&$nextsub;

1;

#---------------------------------------------------------
# sample report

sub sample {

    my @charge_codes = $dbs->query(qq|SELECT charge_code, charge_desc FROM hc_charge_codes ORDER BY 1|)->arrays;

    my $form1 = CGI::FormBuilder->new(
        method     => 'post',
        table      => 1,
        fields     => [qw(charge_code charge_desc)],
        options    => { charge_code => \@charge_codes, },
        messages   => { form_required_text => '', },
        labels     => { charge_code => 'Charge Code', },
        submit     => [qw(Search)],
        params     => $q,
        stylesheet => 1,
        template   => {
            type     => 'TT2',
            template => 'tmpl/search.tmpl',
            variable => 'form1',
        },
        keepextras => [qw(report_name action)],
    );
    $form1->field( name => 'charge_code', type => 'select' );

    print $q->header();
    print $form1->render;

    my $table = $dbs->query(qq|SELECT charge_code, charge_desc FROM hc_charge_codes ORDER BY charge_code|)->xto();

    $table->modify( table => { cellpadding => "3", cellspacing => "2" } );
    $table->modify( tr => { class => [ 'listrow0', 'listrow1' ] } );
    $table->modify( th => { class => 'listheading' }, 'head' );
    $table->modify( th => { class => 'listtotal' },   'foot' );
    $table->modify( th => { class => 'listsubtotal' } );
    $table->modify( th => { align => 'center' },      'head' );
    $table->modify( th => { align => 'right' },       'foot' );
    $table->modify( th => { align => 'right' } );

    print $table->output;
    print qq|
</body>
</html>
|;
}

#----------------------------------------
sub banquet {
    my $vars = {};
    $vars->{hdr} = $dbs->query( 'SELECT * FROM banquet_header WHERE event_number=?', $id )->hash;
    $vars->{dtl} = $dbs->query( 'SELECT * FROM banquet_lines WHERE event_number=?',  $id )->map_hashes('id');
    $vars->{dayname} = $dbs->query( "SELECT TO_CHAR(event_date, 'DAY') FROM banquet_header WHERE event_number=?",  $id )->list;
    $vars->{hdr}->{setup_detail} =~ s/\n/<br>/g;
    print $q->header();
    $tt->process( "$tmpl.tmpl", $vars ) || die $tt->error(), "\n";
}

#----------------------------------------
sub report_header {

    my $report_title = shift;

    print $q->header();

    print qq|
<html>
<head>
 <title>$report_title</title>
 <link rel="stylesheet" href="/munshi9/standard.css" type="text/css">
<link rel="stylesheet" href="/munshi9/standard.css" type="text/css">
<link type="text/css" href="/munshi9/css/start/jquery-ui-1.8.10.custom.css" rel="Stylesheet" />
<script type="text/javascript" language="javascript" src="/munshi9/js/jquery-1.4.4.min.js"></script>
<script type="text/javascript" language="javascript" src="/munshi9/js/jquery.validate.min.js"></script>
<script type="text/javascript" language="javascript" src="/munshi9/js/jquery-ui-1.8.10.custom.min.js"></script>
<script type="text/javascript" language="javascript" src="/munshi9/js/jquery.tablesorter.min.js"></script>
|;

    print q|
<script type="text/javascript" charset="utf-8">
    $(document).ready(function() {
    $("input[type='text']:first", document.forms[0]).focus();
       $("#form1").validate();
    })
</script>
<script>
$(function() {
   $( ".datepicker" ).datepicker({
	dateFormat: 'd-M-yy',
	showOn: "button",
	buttonImage: "/munshi9/css/calendar.gif",
	buttonImageOnly: true,
	showOtherMonths: true,
	selectOtherMonths: true,
	changeMonth: true,
	changeYear: true
   }); 

$(function(){
  $("#sortedtable").tablesorter();
});

});
</script>
</head>
|;
    print qq|
<body>
<h1>$report_title</h1>
|;

}

#----------------------------------------
sub runsql {
    &report_header('Sample Report');

    print qq|
<form action="reports.pl" method="post">
SQL: <textarea name="query">| . $q->param('query') . qq|</textarea>
    <hr/>
    <input type=hidden name=nextsub value=$nextsub>
    <input type=submit name=action class=submit value="Update">
</form>
|;
    my $query = $q->param('query');
    die('Invalid query') if $query =~ /(insert|update|delete|drop|create)/i;

    if ( $q->param('action') eq 'Update' ) {
        my $table = $dbs->query($query)->xto(
            table => { cellpadding => "5",          cellspacing => "2" },
            tr    => { class       => [ 'listrow0', 'listrow1' ] },
            th    => { class       => ['listheading'] },
        ) or die( $dbs->error );

        print $table->output;

    }
}

#----------------------------------------
sub sample_report {

    &report_header('Sample Report');

    my @columns        = qw(charge_code charge_date charge_desc amount);
    my @total_columns  = qw(amount);
    my @search_columns = qw(fromdate todate);

    my %sort_positions = {
        charge_code   => 1,
        charge_date   => 2,
        charge_desc   => 3,
        charge_amount => 4,
    };
    my $sort      = $q->param('sort') ? $q->param('sort') : 'charge_code';
    my $sortorder = $q->param('sortorder');
    my $oldsort   = $q->param('oldsort');
    $sortorder = ( $sort eq $oldsort ) ? ( $sortorder eq 'asc' ? 'desc' : 'asc' ) : 'asc';

    print qq|
<form action="reports.pl" method="post">
From date: <input name=fromdate type=text size=12 class="datepicker" value="| . $q->param('fromdate') . qq|"><br/>
To date: <input name=todate type=text size=12 class="datepicker" value="| . $q->param('todate') . qq|"><br/>
Include: |;
    for (@columns) {
        $checked = ( $action eq 'Update' ) ? ( $q->param("l_$_") ? 'checked' : '' ) : 'checked';
        print qq|<input type=checkbox name=l_$_ value="1" $checked> | . ucfirst($_);
    }
    print qq|<br/>
    Subtotal: <input type=checkbox name=l_subtotal value="checked" | . $q->param('l_subtotal') . qq|><br/>
    <hr/>
    <input type=hidden name=nextsub value=$nextsub>
    <input type=submit name=action class=submit value="Update">
</form>
|;

    my @report_columns;
    for (@columns) { push @report_columns, $_ if $q->param("l_$_") }

    my $where = ' 1 = 1 ';
    $where = ' 1 = 2 ' if $action ne 'Update';    # Display data only when Update button is pressed.
    my @bind = ();

    if ( $q->param('fromdate') ) {
        $where .= qq| AND charge_date >= ?|;
        push @bind, $q->param('fromdate');
    }

    if ( $q->param('todate') ) {
        $where .= qq| AND charge_date <= ?|;
        push @bind, $q->param('todate');
    }

    my $query = qq|
        SELECT  charge_code, charge_date, charge_desc, amount
        FROM hc_charges
        WHERE $where
        ORDER BY $sort_positions($sort) $sortorder
    |;

    my @allrows = $dbs->query( $query, @bind )->hashes or die( $dbs->error );

    my ( %tabledata, %totals, %subtotals );

    my $url = "reports.pl?action=$action&nextsub=$nextsub&oldsort=$sort&sortorder=$sortorder&l_subtotal=" . $q->param(l_subtotal);
    for (@report_columns) { $url .= "&l_$_=" . $q->param("l_$_") if $q->param("l_$_") }
    for (@search_columns) { $url .= "&$_=" . $q->param("$_")     if $q->param("$_") }
    for (@report_columns) { $tabledata{$_} = qq|<th><a class="listheading" href="$url&sort=$_">| . ucfirst $_ . qq|</a></th>\n| }

    print qq|
        <table cellpadding="3" cellspacing="2">
        <tr class="listheading">
|;
    for (@report_columns) { print $tabledata{$_} }

    print qq|
        </tr>
|;

    my $groupvalue;
    my $i = 0;
    for $row (@allrows) {
        $groupvalue = $row->{$sort} if !$groupvalue;
        if ( $q->param(l_subtotal) and $row->{$sort} ne $groupvalue ) {
            for (@report_columns) { $tabledata{$_} = qq|<td>&nbsp;</td>| }
            for (@total_columns) { $tabledata{$_} = qq|<th align="right">| . $nf->format_price( $subtotals{$_}, 2 ) . qq|</th>| }

            print qq|<tr class="listsubtotal">|;
            for (@report_columns) { print $tabledata{$_} }
            print qq|</tr>|;
            $groupvalue = $row->{$sort};
            for (@total_columns) { $subtotals{$_} = 0 }
        }
        for (@report_columns) { $tabledata{$_} = qq|<td>$row->{$_}</td>| }
        for (@total_columns) { $tabledata{$_} = qq|<td align="right">| . $nf->format_price( $row->{$_}, 2 ) . qq|</td>| }
        for (@total_columns) { $totals{$_}    += $row->{$_} }
        for (@total_columns) { $subtotals{$_} += $row->{$_} }

        print qq|<tr class="listrow$i">|;
        for (@report_columns) { print $tabledata{$_} }
        print qq|</tr>|;
        $i += 1;
        $i %= 2;
    }

    for (@report_columns) { $tabledata{$_} = qq|<td>&nbsp;</td>| }
    for (@total_columns) { $tabledata{$_} = qq|<th align="right">| . $nf->format_price( $subtotals{$_}, 2 ) . qq|</th>| }

    print qq|<tr class="listsubtotal">|;
    for (@report_columns) { print $tabledata{$_} }
    print qq|</tr>|;

    for (@total_columns) { $tabledata{$_} = qq|<th align="right">| . $nf->format_price( $totals{$_}, 2 ) . qq|</th>| }
    print qq|<tr class="listtotal">|;
    for (@report_columns) { print $tabledata{$_} }
    print qq|</tr>|;
}

#----------------------------------------
sub lookup1 {
    my ( $cname, $default ) = @_;
    my @rows = $dbs->query( q|SELECT cval FROM a$lookup WHERE cname = ? ORDER BY seq|, $cname )->hashes;
    my $option = qq|<option>\n|;
    for $row (@rows) {
        if ( $row->{cval} eq $default ) {
            $option .= qq|<option value="$row->{cval}" selected>$row->{cval}\n|;
        }
        else {
            $option .= qq|<option value="$row->{cval}">$row->{cval}\n|;
        }
    }
    $option;
}

#---------------------------------------------------------------------------------------------------
sub emp {

    my $row = {};
    if ( $q->param('id') ) {
        $row = $dbs->query( '
            SELECT id, emp_num, emp_name,
                    father_name, desig, dept,
                    pymt_type, sex, married,
                    religion, ntn, nid,
                    eobi_num, blood_group, bank_acc,
                    address1, address2, city,
                    phone, email, dob, doj,
                    job_status, reference1, reference2,
                    reference3, basic_pay, house_rent,
                    coveyance, medical, utilities,
                    others, gross_pay
            FROM hr_emp
            WHERE id = ?', $q->param('id') )->hash or die( $dbs->error );
    }

    #-----------------------------------------------
    # DB FORM
    #-----------------------------------------------
    my @form1flds =
      qw(id emp_num emp_name father_name desig dept pymt_type sex married religion ntn nid eobi_num blood_group bank_acc address1 address2 city phone email dob doj job_status reference1 reference2 reference3 basic_pay house_rent coveyance medical utilities others gross_pay );
    my @form1hidden = qw(id);
    my $form1       = CGI::FormBuilder->new(
        method     => 'post',
        table      => 1,
        fields     => \@form1flds,
        required   => [qw(emp_name)],
        submit     => [qw(Save Delete)],
        values     => $row,
        params     => $q,
        stylesheet => 1,
        template   => {
            type     => 'TT2',
            template => 'form.tmpl',
            variable => 'form1',
        },
        keepextras => [qw(nextsub action)],
    );
    for (@form1hidden) { $form1->field( name => $_, type => 'hidden' ) }
    &report_header('Employees database');
    print $form1->render if $q->param('action') eq 'form';

    #-----------------------------------------------
    # DATA BASE PROCESSING
    #-----------------------------------------------
    my $data = $form1->fields;
    $data->{id} *= 1;
    for (qw(action nextsub)) { delete $data->{$_} }
    if ( $form1->submitted eq 'Save' ) {
        if ( $data->{id} ) {
            $dbs->update( 'hr_emp', $data, { id => $data->{id} } );
        }
        else {
            delete $data->{id};
            $dbs->insert( 'hr_emp', $data );
        }
        print qq|Employee saved\n|;
    }
    elsif ( $form1->submitted eq 'Delete' ) {
        $dbs->delete( 'hr_emp', { id => $data->{id} } );
        print qq|Employee deleted\n|;
    }

    #-----------------------------------------------
    # REPORT
    #-----------------------------------------------
    print qq|<a href="$pageurl?nextsub=emp&action=form">Add a new employee</a>|;
    my $table = $dbs->query( "
        SELECT '<a href=reports.pl?nextsub=emp&action=form&id='||id||'>'||emp_num||'</a>' emp_num, 
            emp_name 
        FROM hr_emp 
        ORDER BY id"
      )->xto(
        table => { cellpadding => "5",          cellspacing => "2" },
        tr    => { class       => [ 'listrow0', 'listrow1' ] },
        th    => { class       => ['listheading'] },
      ) or die( $dbs->error );

    print $table->output;
    print qq|</body></html>|;
}
# EOF
