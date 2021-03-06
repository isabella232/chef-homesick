#
# Cookbook Name:: homesick
# Provider:: castle
#
# Copyright 2011, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'pathname'

def load_current_resource
  castle = castles.select{ |c| c[:name] == new_resource.castle }.first
  if castle
    @current_resource = Chef::Resource::HomesickCastle.new(castle[:name])
    @current_resource.source(castle[:source])
  else
    @current_resource = nil
  end
end

action :install do
  if !@current_resource       # castle is not installed
    clone
    update
  end
end

action :update do
  clone if !@current_resource # castle is not installed
  update
end

private

def castles
  Pathname.glob("#{repos_dir}/**/*/.git").map do |c|
    castle = c.dirname
    source = ""
    Dir.chdir castle do
      source = `git config remote.origin.url`.chomp
    end

    { :name   => castle.relative_path_from(repos_dir).to_s,
      :source => source
    }
  end
end

def repos_dir
  @repos_dir ||= home_dir.join('.homesick', 'repos').expand_path
end

def home_dir
  @home_dir ||= Pathname.new(Etc.getpwnam(new_resource.user).dir).expand_path
end

def clone
  execute "homesick clone #{new_resource.source} --force" do
    user  new_resource.user
  end
end

def update
  execute "homesick pull #{new_resource.castle} --force" do
    user  new_resource.user
  end

  execute "homesick symlink #{new_resource.castle} --force" do
    user  new_resource.user
  end
end
