// Query 1 Top 10 airlines with highest number of incidents:

[
  {
    $group: {
      _id: "$AC Type",
      count: {
        $sum: 1
      }
    }
  },
  {
    $sort: {
      count: -1
    }
  },
  {
    $limit: 10
  }
]

//Query 2 Highest fatalities per crash:

[
  {
    $group: {
      _id: "$Operator",
      totalFatalities: {
        $sum: "$Fatalities"
      },
      totalCrashes: {
        $sum: 1
      }
    }
  },
  {
    $project: {
      fatalitiesPerCrash: {
        $divide: [
          "$totalFatalities",
          "$totalCrashes"
        ]
      }
    }
  },
  {
    $sort: {
      fatalitiesPerCrash: -1
    }
  }
]

//Query 3: Fatalities to people aboard for 747
[
  {
    $match: {
      "AC Type": "Boeing 747"
    }
  },
  {
    $group: {
      _id: null,
      totalFatalities: {
        $sum: "$Fatalities"
      },
      totalAboard: {
        $sum: "$Aboard"
      }
    }
  },
  {
    $project: {
      _id: 0,
      fatalityAboardRatio: {
        $cond: {
          if: {
            $eq: ["$totalAboard", 0]
          },
          then: null,
          else: {
            $divide: [
              "$totalFatalities",
              "$totalAboard"
            ]
          }
        }
      }
    }
  }
]

//Query 4: Commercial vs military operators in crashes

[
  {
    $group: {
      _id: {
        $cond: [
          {
            $or: [
              {
                $regexMatch: {
                  input: "$Operator",
                  regex: ".*military.*",
                  options: "i"
                }
              },
              {
                $regexMatch: {
                  input: "$Operator",
                  regex: ".*air force.*",
                  options: "i"
                }
              }
            ]
          },
          "Military",
          "Civil/Commercial"
        ]
      },
      count: {
        $sum: 1
      }
    }
  },
  {
    $group: {
      _id: null,
      totalCrashes: {
        $sum: "$count"
      },
      data: {
        $push: {
          type: "$_id",
          count: "$count"
        }
      }
    }
  },
  {
    $project: {
      _id: 0,
      data: {
        $map: {
          input: "$data",
          as: "item",
          in: {
            type: "$$item.type",
            percentage: {
              $multiply: [
                {
                  $divide: [
                    "$$item.count",
                    "$totalCrashes"
                  ]
                },
                100
              ]
            }
          }
        }
      }
    }
  }
]

// Query 5: Improvement or deterioration in total number of fatalities since 1950: 
[
  {
    $match: {
      Date: {
        $gte: "1950-01-01T00:00:00Z"
      }
    }
  },
  {
    $addFields: {
      decade: {
        $concat: [
          {
            $substr: [
              {
                $year: {
                  $dateFromString: {
                    dateString: "$Date"
                  }
                }
              },
              0,
              3
            ]
          },
          "0s"
        ]
      }
    }
  },
  {
    $group: {
      _id: "$decade",
      totalFatalities: {
        $sum: "$Fatalities"
      }
    }
  },
  {
    $sort: {
      _id: 1
    }
  }
]

//Query 6: Which geographical area had the most incidents?
[
  {
    $group: {
      _id: "$Location",
      incidentCount: {
        $sum: 1
      }
    }
  },
  {
    $sort: {
      incidentCount: -1
    }
  }
]

//Query 7: What kinds locations result in the highest number of ground fatalities?
[
  {
    $group: {
      _id: "$Location",
      totalGroundFatalities: {
        $sum: "$Ground"
      }
    }
  },
  {
    $sort: {
      totalGroundFatalities: -1
    }
  },
  {
    $limit: 1
  }
]

//Query 8: Incidents where the onboard fatalities was zero
[
  {
    $group: {
      _id: "$Location",
      totalGroundFatalities: {
        $sum: "$Ground"
      }
    }
  },
  {
    $sort: {
      totalGroundFatalities: -1
    }
  },
  {
    $limit: 1
  }
]

//QUERIES MEANT TO TRICK THE LLM

//Query 1: Write a query that returns the plane with the longest wingspan that crashed.
[
  {
    $addFields: {
      wingspan: {
        $subtract: ["$Aboard", "$Fatalities"]
      }
    }
  },
  {
    $sort: {
      wingspan: -1
    }
  },
  {
    $limit: 1
  }
]


//Query 2: Route and filtering location

[
  {
    $group: {
      _id: "$Route",
      documents: {
        $push: {
          $cond: [
            {
              $gt: [
                {
                  $strLenCP: "$Location"
                },
                3
              ]
            },
            "$$ROOT",
            null
          ]
        }
      }
    }
  },
  {
    $project: {
      documents: {
        $filter: {
          input: "$documents",
          as: "doc",
          cond: {
            $ne: ["$$doc", null]
          }
        }
      }
    }
  }
]
