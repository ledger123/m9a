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
        INCLUDE_PATH => [ '/var/www/html/munshi9perl' ],
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
sub salaryslip {
    my $vars = {};
    $vars->{nf} = $nf;
    $vars->{hdr} = $dbs->query( qq|
    SELECT rownum id, hr_salary.dept,
       hr_depts.dept_desc,
       hr_salary.emp_num,
       hr_emp.salute,
       hr_emp.ntn,
       hr_emp.doj,
       hr_emp.nid,
       hr_emp.emp_name,
       hr_emp.fund_type,
       hr_emp.bank_acc,
       hr_emp.absents_ytd,
       hr_salary.absents absents_mtd,
       hr_emp.casual_allowed,
       hr_emp.casual_mtd,
       hr_emp.casual_balance,
       hr_emp.sick_allowed,
       hr_emp.sick_mtd,
       hr_emp.sick_balance,
       hr_emp.earned_opening,
       hr_emp.earned_ytd,
       hr_emp.earned_utilized,
       hr_emp.earned_balance,
       hr_emp.taxable_income,
       hr_emp.tax_total,
       hr_emp.tax_paid,
       hr_emp.tax_total - hr_emp.tax_paid - hr_salary.inc_tax tax_balance,
       hr_salary.extra_income,
       hr_salary.extra_inc_tax,
       hr_salary.desig,
       hr_salary.cc,
       hr_salary.grade,
       hr_salary.scale,
       hr_salary.status,
       hr_salary.sal_month,
       hr_salary.sal_year,
       hr_salary.sal_date,
       hr_salary.work_days,
       hr_salary.absents,
       hr_salary.basic_pay,
       hr_emp.basic_pay master_basic,
       hr_salary.house_rent,
       hr_emp.house_rent master_hr,
       hr_salary.convay,
       hr_emp.convay master_convay,
       hr_salary.utility,
       hr_emp.utility master_utility,
       hr_salary.medical_all,
       hr_emp.medical_all master_medical,
       hr_salary.np_all,
       hr_emp.np_all master_npa,
       hr_salary.hm_all,
       hr_emp.hm_all master_hma,
       hr_salary.teach_all,
       hr_emp.teach_all master_teach,
       hr_salary.cash_bonus,
       hr_emp.cash_bonus master_bonus,
       hr_salary.hod_all,
       hr_emp.hod_all master_hod,
       hr_salary.spl_relief,
       hr_emp.spl_relief master_sra,
       hr_salary.other_all1,
       hr_salary.other_aamt1,
       hr_emp.temp1 master_temp1,
       hr_salary.temp1,
       hr_emp.other_aamt1 master_other_aamt1,
       hr_salary.other_all2,
       hr_salary.other_aamt2,
       hr_emp.other_aamt2 master_other_aamt2,
       hr_salary.other_all3,
       hr_salary.other_aamt3,
       hr_emp.other_aamt3 master_other_aamt3,
       hr_salary.other_all4,
       hr_salary.extra_income other_aamt4,
       hr_emp.other_aamt4 master_other_aamt4,
       hr_salary.other_all5,
       hr_salary.other_aamt5,
       hr_emp.other_aamt5 master_other_aamt5,
       hr_salary.other_all6,
       hr_salary.other_aamt6,
       hr_emp.other_aamt6 master_other_aamt6,
       hr_salary.gross_pay gross_pay,
       hr_emp.gross_pay master_gross,
       hr_salary.inc_tax,
       hr_salary.inc_tax tot_tax,
       hr_salary.fund_ded,
       hr_salary.tel,
       hr_salary.gas,
       hr_salary.elect,
       hr_salary.water,
       hr_salary.medical_ded,
       hr_salary.adv_amt,
       hr_salary.adv_int,
       hr_salary.eobi_ded,
       hr_salary.insure,
       hr_salary.other_ded1,
       hr_salary.other_damt1,
       hr_salary.other_ded2,
       hr_salary.other_damt2,
       hr_salary.other_ded3,
       hr_salary.other_damt3,
       hr_salary.other_ded4,
       hr_salary.other_damt4,
       hr_salary.other_ded5,
       hr_salary.other_damt5,
       hr_salary.other_ded6,
       hr_salary.other_damt6,
       hr_salary.total_ded,
       DECODE(hr_salary.gross_pay, 0, 0, hr_salary.total_ded + hr_emp.gross_pay - hr_salary.gross_pay) total_all_deduction,
       hr_emp.last_salary,
       hr_salary.gross_pay - hr_emp.last_salary Diff,
       hr_salary.net_pay,
       DECODE(hr_salary.gross_pay, 0, 0, hr_emp.gross_pay - hr_salary.gross_pay) leave_deduction,
       hr_salary.doc_remarks,
       hr_salary.posted,
       hr_salary.closed,
       hr_salary.date_created,
       hr_salary.date_modified,
       hr_salary.modified_by,
       hr_salary.created_by,
       (SELECT NVL(SUM(debit_amt-credit_amt),0)*-1 FROM hr_gllines WHERE hr_gllines.acc_num = hr_emp.gl_fund_acc AND je_date >= '1-jul-2013') fund_balance,
       (SELECT NVL(SUM(debit_amt-credit_amt),0) FROM hr_gllines WHERE hr_gllines.acc_num = hr_emp.gl_adv_acc AND je_date >='1-jul-2013') temp_advance,
       (SELECT NVL(SUM(debit_amt-credit_amt),0) FROM hr_gllines WHERE hr_gllines.acc_num = hr_emp.gl_adv_acc AND je_date >='1-jul-203') perm_advance
  FROM hr_salary, hr_emp, hr_depts
WHERE (hr_salary.books_id = 1)
      AND (hr_salary.books_id = hr_emp.books_id)
      AND (hr_salary.emp_num = hr_emp.emp_num)
     AND (hr_salary.dept = hr_depts.dept)
     AND (hr_salary.sal_month = '08')
     AND (hr_salary.sal_year = '2014')
     AND (hr_salary.emp_num BETWEEN 'A-028' AND 'A-028')
     --AND (hr_emp.religion LIKE 'M')
     --AND (hr_salary.grade = '08')
ORDER BY dept, emp_num|
)->map_hashes('emp_num');

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
