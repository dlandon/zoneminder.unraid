#!/usr/bin/perl
#
# pushapi_pushover.pl - Pushover integration for ZoneMinder Event Notification
#
# Copyright (C) 2025  Dan Landon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use Config::Tiny;
use Sys::Syslog qw(:standard :macros);
use File::Spec;
use File::Basename;

# -----------------------------
# Read Pushover credentials
# -----------------------------
my $secrets_file = '/etc/zm/secrets.ini';
my $cfg = Config::Tiny->read($secrets_file)
	or die "Failed to read $secrets_file: ", Config::Tiny->errstr;

my $api_token = $cfg->{PUSHOVER}->{api_token} // $cfg->{secrets}->{PUSHOVER_APP_TOKEN} // die "Missing api_token";
my $user_key  = $cfg->{PUSHOVER}->{user_key}  // $cfg->{secrets}->{PUSHOVER_USER_KEY} // die "Missing user_key";

# -----------------------------
# Read optional per-monitor sounds and debug level
# -----------------------------
my $ini_file = '/etc/zm/zmeventnotification.ini';
my $ini = Config::Tiny->read($ini_file)
	or die "Failed to read $ini_file: ", Config::Tiny->errstr;

my $sounds_cfg  = $ini->{push}->{monitor_sounds} // '';
my $debug_level = $ini->{customize}->{es_debug_level} // 0;

# -----------------------------
# Logging helpers
# -----------------------------
openlog('zmeventnotification', 'pid', 'user');
sub log_debug {
	my ($level, $msg) = @_;
	syslog('info', "[DEBUG] $msg") if $debug_level >= $level;
}

# -----------------------------
# Parse monitor sounds config
# -----------------------------
my %monitor_sounds;
foreach my $entry (split /,/, $sounds_cfg) {
	next unless $entry =~ /\S/;
	if ($entry =~ /"(.*?)"\s*:\s*"(.*?)"/) {
		my ($name, $sound) = ($1, $2);
		$monitor_sounds{$name} = $sound;
		log_debug(2, "Parsed monitor sound: $name -> $sound");
	}
}

# -----------------------------
# Arguments from zmeventnotification
# -----------------------------
my ($event_id, $monitor_id, $monitor_name, $alarm_cause, $event_type, $image_path) = @ARGV;

log_debug(1, "eid:$event_id Arguments received: monitor='$monitor_name', cause='$alarm_cause', type='$event_type', image_path='$image_path'");

# -----------------------------
# Build pushover message
# -----------------------------
my $message = "ZM Event: $monitor_name\nCause: $alarm_cause\nType: $event_type\nEventID: $event_id";
my $title   = "Zoneminder Alert: $monitor_name";
$title = "Ended: $title" if $event_type eq 'event_end';

log_debug(1, "eid:$event_id Message: $message");
log_debug(1, "eid:$event_id Title: $title");

my $ua = LWP::UserAgent->new;
my %post_data = (
	token    => $api_token,
	user     => $user_key,
	message  => $message,
	title    => $title,
	priority => 0,  # normal priority
);

# -----------------------------
# Determine Pushover sound
# -----------------------------
my $sound = $monitor_sounds{$monitor_name} // 'pushover';
$post_data{sound} = $sound;
log_debug(1, "eid:$event_id Using sound: $sound");

# -----------------------------
# Determine actual image to send
# -----------------------------
my $chosen_image;
if (defined $image_path && -d $image_path) {

	my $objdetect_gif   = File::Spec->catfile($image_path, 'objdetect.gif');
	my $objdetect_jpg   = File::Spec->catfile($image_path, 'objdetect.jpg');
	my $alarm_file      = File::Spec->catfile($image_path, 'alarm.jpg');
	my $snapshot_file   = File::Spec->catfile($image_path, 'snapshot.jpg');

	if (-f $objdetect_gif) {
		$chosen_image = $objdetect_gif;
	} elsif (-f $objdetect_jpg) {
		$chosen_image = $objdetect_jpg;
	} elsif (-f $alarm_file) {
		$chosen_image = $alarm_file;
	} elsif (-f $snapshot_file) {
		$chosen_image = $snapshot_file;
	}

	if ($chosen_image) {
		log_debug(1, "eid:$event_id Using image '$chosen_image'");
	} else {
		log_debug(1, "eid:$event_id No image found in directory '$image_path'");
	}
}

# Attach image if valid
$post_data{attachment} = [$chosen_image] if defined $chosen_image && -f $chosen_image;

# -----------------------------
# Send notification
# -----------------------------
my $response;
if ($chosen_image) {
	log_debug(2, "eid:$event_id Sending pushover with attachment");
	$response = $ua->request(
		POST 'https://api.pushover.net/1/messages.json',
		Content_Type => 'form-data',
		Content      => [ %post_data, attachment => [$chosen_image] ]
	);
} else {
	log_debug(2, "eid:$event_id Sending pushover without attachment");
	$response = $ua->post('https://api.pushover.net/1/messages.json', \%post_data);
}

if ($response->is_success) {
	log_debug(1, "eid:$event_id Pushover sent successfully for monitor '$monitor_name', using sound '$sound'");
} else {
	log_debug(1, "eid:$event_id Pushover failed for monitor '$monitor_name': " . $response->status_line);
}

closelog();
exit(0);
